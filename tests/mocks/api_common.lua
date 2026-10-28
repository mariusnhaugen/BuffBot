-- WoW API surface shared by every client flavor: units, auras, group state,
-- frames and the Settings API. api_forever adds the C_Spell functions and
-- frame templates.
local Spells = require("mocks.spells")

-- Frame methods that the addon calls but that have no observable effect in
-- tests. Calls are recorded in frame.calls so specs can still assert on them.
local NOOP_METHODS = {
    "SetSize", "SetWidth", "SetHeight", "SetClampedToScreen", "SetMovable",
    "StartMoving", "StopMovingOrSizing", "SetAllPoints", "SetColorTexture",
    "RegisterForClicks", "RegisterForDrag", "SetFrameStrata",
}

local Region = {}
Region.__index = Region

for _, method in ipairs(NOOP_METHODS) do
    Region[method] = function(self, ...)
        self.calls[method] = { ... }
    end
end

function Region:GetName() return self.name end

function Region:GetParent() return self.parent end

function Region:SetAttribute(key, value) self.attributes[key] = value end

function Region:GetAttribute(key) return self.attributes[key] end

function Region:SetScript(event, fn) self.scripts[event] = fn end

function Region:GetScript(event) return self.scripts[event] end

function Region:RegisterEvent(event) self.events[event] = true end

-- Unit events store the units they were registered for; fire() filters on them
function Region:RegisterUnitEvent(event, ...) self.events[event] = { ... } end

function Region:UnregisterEvent(event) self.events[event] = nil end

function Region:IsEventRegistered(event) return self.events[event] ~= nil end

function Region:Show() self.shown = true end

function Region:Hide() self.shown = false end

function Region:IsShown() return self.shown end

function Region:IsVisible()
    if not self.shown then return false end
    if self.parent and self.parent.IsVisible then return self.parent:IsVisible() end
    return true
end

function Region:SetPoint(...) self.points = { { ... } } end

function Region:GetPoint() return unpack(self.points[1] or {}) end

function Region:ClearAllPoints() self.points = {} end

function Region:SetNormalTexture(texture)
    self.normalTexture = self.normalTexture or setmetatable({ kind = "Texture", calls = {} }, Region)
    self.normalTexture.file = texture
end

function Region:GetNormalTexture() return self.normalTexture end

function Region:GetTexture() return self.file end

function Region:SetVertexColor(r, g, b) self.vertexColor = { r, g, b } end

function Region:EnableMouse(enabled) self.mouseDisabled = not enabled end

function Region:IsMouseEnabled() return not self.mouseDisabled end

function Region:SetAlpha(alpha) self.alpha = alpha end

function Region:GetAlpha() return self.alpha or 1 end

function Region:GetVertexColor() return unpack(self.vertexColor or { 1, 1, 1 }) end

function Region:SetText(text) self.text_ = text end

function Region:GetText() return self.text_ end

function Region:SetChecked(checked) self.checked = checked and true or false end

function Region:GetChecked() return self.checked end

function Region:Click(button)
    if self.kind == "CheckButton" then
        self.checked = not self.checked
    end
    local onClick = self.scripts.OnClick
    if onClick then onClick(self, button or "LeftButton", false) end
end

local function newRegion(env, kind, name, parent)
    local region = setmetatable({
        env = env,
        kind = kind,
        name = name,
        parent = parent,
        attributes = {},
        scripts = {},
        events = {},
        points = {},
        calls = {},
        children = {},
        shown = true,
    }, Region)
    if parent then table.insert(parent.children, region) end
    return region
end

function Region:CreateFontString(name)
    local fs = newRegion(self.env, "FontString", name, self)
    if name then self.env[name] = fs end
    return fs
end

function Region:CreateTexture(name)
    local tex = newRegion(self.env, "Texture", name, self)
    if name then self.env[name] = tex end
    return tex
end

return function(state, env)
    state.newRegion = function(kind, name, parent) return newRegion(env, kind, name, parent) end
    state.templates.SecureActionButtonTemplate = function() end
    state.templates.UIPanelButtonTemplate = function() end

    function env.CreateFrame(kind, name, parent, template)
        local frame = newRegion(env, kind, name, parent)
        if template then
            local apply = state.templates[template]
            if not apply then
                error("CreateFrame: unknown template " .. template, 2)
            end
            apply(frame, env)
        end
        if name then env[name] = frame end
        table.insert(state.frames, frame)
        return frame
    end

    env.UIParent = newRegion(env, "Frame", "UIParent")

    -- Units, group and combat
    local function member(unit)
        return state.members[unit]
    end

    function env.UnitClass(unit)
        local m = unit and member(unit)
        local class = m and m.class or state.class
        return class:sub(1, 1) .. class:sub(2):lower(), class, 1
    end

    function env.GetUnitName(unit)
        if state:resolve(unit) == "player" then return state.playerName end
        local m = member(unit)
        return m and m.name
    end

    -- Classic Era's order: name, icon, points spent, file name. With inspect,
    -- the inspected member's talents (member.talents).
    function env.GetTalentTabInfo(tab, inspect)
        local talents = state.talents
        if inspect then
            local m = state.inspecting and member(state.inspecting)
            talents = m and m.talents or {}
        end
        return "Tree " .. tab, "icon", talents[tab] or 0, "Tree" .. tab
    end

    -- Inspect: in range unless member.inRange is false. Specs fire
    -- INSPECT_READY themselves; state.inspects lists the units asked for.
    function env.CanInspect(unit)
        local m = member(unit)
        return m ~= nil and m.inRange ~= false and not m.offline
    end

    function env.NotifyInspect(unit)
        state.inspecting = unit
        table.insert(state.inspects, unit)
    end

    function env.ClearInspectPlayer()
        state.inspecting = nil
    end

    function env.UnitName(unit)
        if state:resolve(unit) == "player" then return state.playerName end
        local m = member(unit)
        return m and m.name
    end

    -- A member's guid field, or one made from their name
    function env.UnitGUID(unit)
        if state:resolve(unit) == "player" then return "Player-" .. state.playerName end
        local m = member(unit)
        return m and (m.guid or ("Player-" .. m.name))
    end

    function env.UnitExists(unit)
        return state:resolve(unit) == "player" or member(unit) ~= nil
    end

    function env.UnitIsConnected(unit)
        local m = member(unit)
        if m then return not m.offline end
        return state:resolve(unit) == "player"
    end

    function env.UnitIsVisible(unit)
        local m = member(unit)
        if m then return m.visible ~= false end
        return state:resolve(unit) == "player"
    end

    function env.UnitIsUnit(a, b)
        return state:resolve(a) == state:resolve(b)
    end

    local function memberCount()
        local count = 0
        for _ in pairs(state.members) do count = count + 1 end
        return count
    end

    function env.GetNumGroupMembers()
        if not (state.group or state.raid) then return 0 end
        return 1 + memberCount()
    end

    function env.GetNumSubgroupMembers()
        if state.raid or not state.group then return 0 end
        return memberCount()
    end

    -- name, rank, subgroup, level, class, fileName, zone, online, isDead,
    -- role, isML, combatRole
    function env.GetRaidRosterInfo(index)
        if not state.raid then return nil end
        if index == 1 then
            return state.playerName, 0, state.playerSubgroup, 60, state.class, state.class, "Zone", true, false,
                nil, false, state.combatRole or "NONE"
        end
        local m = member("raid" .. index)
        if m then
            return m.name, 0, m.subgroup, 60, m.class, m.class, "Zone", not m.offline, m.dead == true,
                nil, false, m.combatRole or "NONE"
        end
    end

    -- The raid's main-tank marks: member.mainTank, or state.mainTank for the player
    function env.GetPartyAssignment(assignment, unit)
        if assignment ~= "MAINTANK" then return false end
        if state:resolve(unit) == "player" then return state.mainTank == true end
        local m = member(unit)
        return m and m.mainTank == true or false
    end

    function env.UnitLevel() return 60 end

    function env.InCombatLockdown() return state.combat end

    function env.UnitIsDeadOrGhost(unit)
        local m = member(unit)
        if m then return m.dead == true end
        return state:resolve(unit) == "player" and (state.dead or state.ghost)
    end

    function env.UnitOnTaxi(unit) return unit == "player" and state.taxi end

    function env.IsInInstance()
        return state.instanceType ~= "none", state.instanceType
    end

    function env.UnitCastingInfo(unit)
        if unit == "player" and state.casting then return "Hearthstone" end
    end

    function env.UnitChannelInfo() return nil end

    function env.IsInGroup() return state.group or state.raid end

    function env.IsInRaid() return state.raid end

    function env.UnitInRaid(unit)
        if unit == "player" and state.raid then return 1 end
        return nil
    end

    function env.IsAltKeyDown() return state.altDown == true end

    function env.GetTime() return state.time end

    env.LE_PARTY_CATEGORY_HOME = 1

    -- Auras, for the player and the group members
    env.C_UnitAuras = {
        GetAuraDataBySpellName = function(unit, name, filter)
            local auras = state:aurasOf(unit)
            if not auras then return nil end
            local english = state:englishName(name)
            local aura = english and auras[english]
            if not aura then return nil end
            -- The PLAYER filter only returns auras the player cast
            if filter and filter:find("PLAYER") and not aura.isFromPlayerOrPlayerPet then return nil end
            local copy = {}
            for k, v in pairs(aura) do copy[k] = v end
            copy.name = state:localName(english)
            return copy
        end,
    }

    -- Spellbook lookups that exist on every client
    function env.IsPlayerSpell(id)
        local name = Spells.nameOf(id)
        return name ~= nil and state:knows(name)
    end

    -- Settings API, vertical layout. Settings are kept by their label in
    -- state.settings, and what the page shows in each category's initializers.
    local function newInitializer(category, init)
        table.insert(category.initializers, init)
        return init
    end

    env.Settings = {
        VarType = { Boolean = "boolean", String = "string" },
        RegisterVerticalLayoutCategory = function(name)
            local category = { name = name, ID = name, initializers = {} }
            function category:GetID() return self.ID end

            local layout = {}
            function layout:AddInitializer(init) newInitializer(category, init) end

            state.categories[name] = category
            return category, layout
        end,
        RegisterAddOnSetting = function(_, variable, key, tbl, varType, name, default)
            assert(type(default) == varType, "default for " .. variable .. " is not a " .. varType)
            if tbl[key] == nil then tbl[key] = default end
            local setting = { variable = variable, name = name, default = default }
            function setting:GetValue() return tbl[key] end
            function setting:SetValue(value)
                tbl[key] = value
                if self.callback then self.callback(self, value) end
            end
            function setting:SetValueChangedCallback(callback) self.callback = callback end
            state.settings[name] = setting
            return setting
        end,
        CreateCheckbox = function(category, setting, tooltip)
            return newInitializer(category, { kind = "checkbox", setting = setting, tooltip = tooltip })
        end,
        CreateDropdown = function(category, setting, options, tooltip)
            return newInitializer(category,
                { kind = "dropdown", setting = setting, options = options, tooltip = tooltip })
        end,
        CreateControlTextContainer = function()
            local container = { data = {} }
            function container:Add(value, label) table.insert(self.data, { value = value, label = label }) end
            function container:GetData() return self.data end
            return container
        end,
        RegisterAddOnCategory = function(category) category.registered = true end,
        OpenToCategory = function(id) state.openedCategory = id end,
    }

    function env.CreateSettingsButtonInitializer(name, buttonText, onClick, tooltip)
        return { kind = "button", name = name, buttonText = buttonText, onClick = onClick, tooltip = tooltip }
    end

    function env.CreateSettingsListSectionHeaderInitializer(name)
        return { kind = "header", name = name }
    end

    -- Misc
    env.SlashCmdList = {}

    function env.print(...)
        local parts = {}
        for i = 1, select("#", ...) do parts[#parts + 1] = tostring((select(i, ...))) end
        table.insert(state.printed, table.concat(parts, " "))
    end
end
