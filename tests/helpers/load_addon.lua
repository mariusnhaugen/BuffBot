-- Loads the addon into a fresh sandbox per test, the way the client does:
-- files in TOC order, each called with (addonName, namespace).
local State = require("mocks.state")
local Items = require("mocks.items")

local ADDON_NAME = "BuffBot"

local function tocFiles(path)
    local files = {}
    for line in io.lines(path) do
        line = line:gsub("\r$", ""):match("^%s*(.-)%s*$")
        if line ~= "" and not line:match("^#") then
            table.insert(files, line)
        end
    end
    return files
end

local Harness = {}
Harness.__index = Harness

local function accepts(registration, unit)
    if registration == true then return true end
    for _, registered in ipairs(registration) do
        if registered == unit then return true end
    end
    return false
end

function Harness:fire(event, ...)
    for _, frame in ipairs(self.state.frames) do
        local onEvent = frame:GetScript("OnEvent")
        local registration = frame.events[event]
        if registration and onEvent and accepts(registration, (...)) then
            onEvent(frame, event, ...)
        end
    end
end

function Harness:slash(arg)
    self.env.SlashCmdList.BUFFBOTSETTINGS(arg or "")
end

-- State changes, each followed by the event the client would fire.
function Harness:refresh()
    self:fire("UNIT_AURA", "player", {})
end

-- Takes English or client names, so buffUp can pass what the button shows.
-- Imbues and poisons ("Instant Poison on 17") go on the weapon instead.
function Harness:give(name, opts)
    local invSlot = name:match("^.+ on (1[67])$")
    if invSlot then
        return self:enchantWeapon(2, nil, { slot = tonumber(invSlot) - 16, charges = 60 })
    end
    local english = self.state:englishName(name) or name
    if self.ns.WeaponImbues[english] then
        return self:enchantWeapon(3)
    end
    self.state:giveAura(english, opts)
    self:auraChanged(opts and opts.unit)
end

-- Another unit's change goes through the scheduled re-check, so the clock
-- moves on past it
function Harness:auraChanged(unit)
    if not unit or self.state:resolve(unit) == "player" then return self:refresh() end
    self:fire("UNIT_AURA", unit, {})
    self.state:advance(0.5)
end

function Harness:remove(name, unit)
    self.state:removeAura(name, unit)
    if unit and unit ~= "player" then return self:auraChanged(unit) end
    self:fire("UNIT_AURA", "player", { removedAuraInstanceIDs = { 1 } })
end

function Harness:learn(...)
    self.state:learn(...)
    self:fire("SPELLS_CHANGED")
end

-- Out of mana or rage for a spell
function Harness:setOutOfPower(name, out)
    self.state.unusable[name] = out or nil
    self:fire("SPELL_UPDATE_USABLE")
end

function Harness:die()
    self.state.dead = true
    self:fire("PLAYER_DEAD")
end

function Harness:releaseSpirit()
    self.state.dead, self.state.ghost = false, true
    self:fire("PLAYER_ALIVE")
end

function Harness:resurrect()
    self.state.dead, self.state.ghost = false, false
    self:fire("PLAYER_UNGHOST")
end

-- The control events fire before UnitOnTaxi changes, as in the probe
function Harness:takeTaxi()
    self:fire("PLAYER_CONTROL_LOST")
    self.state.taxi = true
    self.state:advance(1)
end

function Harness:landTaxi()
    self:fire("PLAYER_CONTROL_GAINED")
    self.state.taxi = false
    self.state:advance(1)
end

-- type 2 for an oil, stone or poison, 3 for an imbue; timeLeft in ms (default
-- 1 hour). opts: slot (0 main hand, the default, or 1 off hand), charges.
function Harness:enchantWeapon(type, timeLeft, opts)
    opts = opts or {}
    self.state.weaponEnchants[opts.slot or 0] = { type = type, timeLeft = timeLeft or 3600000, charges = opts.charges }
    self:fire("UNIT_INVENTORY_CHANGED", "player")
end

function Harness:clearWeaponEnchant(slot)
    self.state.weaponEnchants[slot or 0] = nil
    self:fire("UNIT_INVENTORY_CHANGED", "player")
end

function Harness:equipOffHand(itemID)
    self.state.offHand = itemID
    self:fire("UNIT_INVENTORY_CHANGED", "player")
end

-- Sets how many of an item (by English name) are in the bags; 0 for none
function Harness:bag(name, count)
    local id = assert(Items.idOf(name), "unknown item " .. name)
    count = count or 1
    self.state.bags[id] = count > 0 and count or nil
    self:fire("BAG_UPDATE_DELAYED")
end

function Harness:enterCombat()
    self.state.combat = true
    self:fire("PLAYER_REGEN_DISABLED")
end

function Harness:leaveCombat()
    self.state.combat = false
    self:fire("PLAYER_REGEN_ENABLED")
end

-- A member: { name, class, subgroup, dead, offline, visible, inRange };
-- class defaults to WARRIOR
local function addMembers(state, members, prefix, first)
    state.members = {}
    for i, m in ipairs(members or {}) do
        m.class = m.class or "WARRIOR"
        m.name = m.name or (prefix .. (first + i - 1))
        m.subgroup = m.subgroup or 1
        m.auras = {}
        state.members[prefix .. (first + i - 1)] = m
    end
end

function Harness:joinParty(members)
    self.state.group, self.state.raid = true, false
    addMembers(self.state, members, "party", 1)
    self:fire("GROUP_ROSTER_UPDATE")
end

-- The player is raid1, in subgroup playerSubgroup (default 1); members are
-- raid2 on
function Harness:joinRaid(members, playerSubgroup)
    self.state.group, self.state.raid = true, true
    self.state.playerSubgroup = playerSubgroup or 1
    addMembers(self.state, members, "raid", 2)
    self:fire("GROUP_ROSTER_UPDATE")
end

function Harness:leaveGroup()
    self.state.group, self.state.raid = false, false
    self.state.members = {}
    self:fire("GROUP_LEFT")
end

-- Changes a member, then lets the range poll notice
function Harness:setMember(unit, fields)
    for key, value in pairs(fields) do
        self.state.members[unit][key] = value
    end
    self.state:advance(2)
end

function Harness:setting(key, value)
    self.ns.config[key] = value
    self.ns.UpdateClassBuffList()
end

-- Observations
-- The spell the button casts, or "<item> on <slot>" for an item it uses on
-- a weapon, by English item name
function Harness:shown()
    if not self.button:IsShown() then return nil end
    local macro = self.button:GetAttribute("macrotext1")
    if not macro then return nil end
    local itemID, invSlot = macro:match("^/use item:(%d+)\n/use (%d+)$")
    if itemID then
        return Items.nameOf(tonumber(itemID)) .. " on " .. invSlot
    end
    return macro:match("^/cast %[target=[^%]]+%](.+)$")
end

-- The unit the button casts on, or nil
function Harness:target()
    if not self.button:IsShown() then return nil end
    return (self.button:GetAttribute("macrotext1") or ""):match("^/cast %[target=([^%]]+)%]")
end

-- Who a cast lands on: a group version reaches the target's whole subgroup,
-- apart from members who are dead, offline or out of range
function Harness:landsOn(buff, unit)
    local isGroupVersion = false
    for _, versions in pairs(self.ns.GroupVersions) do
        if versions[1] == (self.state:englishName(buff) or buff) then isGroupVersion = true end
    end
    if not isGroupVersion then return { unit } end
    local units = {}
    for _, other in ipairs(self.state:subgroupOf(unit)) do
        local m = self.state.members[other]
        if not m or not (m.dead or m.offline or m.inRange == false) then table.insert(units, other) end
    end
    return units
end

function Harness:suggestions()
    local texts = {}
    for _, fs in ipairs(self.ns.suggestionList or {}) do
        if fs:IsShown() then table.insert(texts, fs:GetText()) end
    end
    return texts
end

-- Presses the button until nothing is left, returning the buffs in cast order.
-- Casts on someone other than the player read "<buff> > <unit>".
function Harness:buffUp()
    local cast = {}
    for _ = 1, 20 do
        local buff, unit = self:shown(), self:target()
        if not buff then return cast end
        local landsOn = self:landsOn(buff, unit or "player")
        if #landsOn == 1 and self.state:resolve(landsOn[1]) == "player" then
            table.insert(cast, buff)
            self:give(buff)
        else
            table.insert(cast, unit == "player" and buff or (buff .. " > " .. unit))
            for _, other in ipairs(landsOn) do
                self.state:giveAura(self.state:englishName(buff) or buff, { unit = other })
            end
            self:auraChanged(unit)
            self:refresh()
        end
    end
    error("buffUp did not converge: " .. table.concat(cast, ", "))
end

-- A setting on the BuffBot settings page, by its label
function Harness:settingNamed(label)
    return assert(self.state.settings[label], "missing setting " .. label)
end

-- What the settings page shows for a label: its checkbox or dropdown
function Harness:control(label)
    for _, init in ipairs(self.state.categories.BuffBot.initializers) do
        if init.setting and init.setting.name == label then return init end
    end
    error("no control for " .. label)
end

-- A settings dropdown's options: { text, selected, pick }
function Harness:dropdown(label)
    local control = self:control(label)
    local options = {}
    for _, option in ipairs(control.options()) do
        table.insert(options, {
            text = option.label,
            selected = control.setting:GetValue() == option.value,
            pick = function() control.setting:SetValue(option.value) end,
        })
    end
    return options
end

-- The text of the selected option, or nil
function Harness:selected(label)
    for _, option in ipairs(self:dropdown(label)) do
        if option.selected then return option.text end
    end
end

function Harness:choose(label, text)
    for _, option in ipairs(self:dropdown(label)) do
        if option.text == text then return option.pick() end
    end
    error("no option " .. text .. " in " .. label)
end

function Harness:printed(pattern)
    for _, line in ipairs(self.state.printed) do
        if line:find(pattern, 1, true) then return true end
    end
    return false
end

local M = {}

-- opts:
--   class   player class token (default WARRIOR)
--   known   list of known spell names
--   saved   BuffBotConfig SavedVariables value before load (default nil)
--   charSaved  BuffBotCharConfig value before load (default nil)
--   config  config overrides applied after ADDON_LOADED
--   raid    start in a raid
--   translate  function mapping English spell names to the client's names
function M.load(opts)
    opts = opts or {}
    local state = State.new(opts.class)
    state.translate = opts.translate
    state:learn(unpack(opts.known or {}))
    if opts.raid then state.group, state.raid = true, true end

    local env = setmetatable({}, { __index = _G })
    env._G = env
    require("mocks.api_common")(state, env)
    require("mocks.api_forever")(state, env)
    env.BuffBotConfig = opts.saved
    env.BuffBotCharConfig = opts.charSaved

    local ns = {}
    for _, file in ipairs(tocFiles(ADDON_NAME .. ".toc")) do
        local chunk = assert(loadfile(file))
        setfenv(chunk, env)
        chunk(ADDON_NAME, ns)
    end

    local h = setmetatable({ state = state, env = env, ns = ns, button = ns.macroButton }, Harness)
    h:fire("ADDON_LOADED", ADDON_NAME)
    for key, value in pairs(opts.config or {}) do
        ns.config[key] = value
    end
    h:fire("SPELLS_CHANGED")
    return h
end

return M
