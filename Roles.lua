local _, BuffBot = ...

-- Raid members get blessings by role rather than class (docs/plan/SPEC.md).
-- Parties keep the class lists in BuffBot.BlessingPriority.
local MIGHT, WISDOM, KINGS = "Blessing of Might", "Blessing of Wisdom", "Blessing of Kings"

-- Blessings by role, best first. Light isn't on any list: it's the filler a
-- Paladin gives when nothing on the list is left.
BuffBot.RoleLists = {
    tank = { KINGS, MIGHT },
    melee = { MIGHT, KINGS },
    ranged = { KINGS, WISDOM, MIGHT },
    caster = { WISDOM, KINGS },
    healer = { WISDOM, KINGS },
}

-- The role a class has until something says otherwise. Hybrids default to
-- healer.
BuffBot.ClassDefaultRole = {
    WARRIOR = "melee",
    ROGUE = "melee",
    HUNTER = "ranged",
    MAGE = "caster",
    WARLOCK = "caster",
    PRIEST = "healer",
    DRUID = "healer",
    SHAMAN = "healer",
    PALADIN = "healer",
}

-- The role of each talent tree, by class, for the classes whose trees differ
local TalentTreeRoles = {
    DRUID = { "caster", "melee", "healer" },
    SHAMAN = { "caster", "melee", "healer" },
    PALADIN = { "healer", "tank", "melee" },
    WARRIOR = { "melee", "melee", "tank" },
}

-- Points spent in one talent tree, the player's or, with inspect, the
-- inspected unit's. Classic Era returns them third; later clients return an
-- ID first and the points fifth.
local function PointsIn(tab, inspect)
    local _, _, third, _, fifth = GetTalentTabInfo(tab, inspect)
    if type(third) == "number" then return third end
    return fifth or 0
end

-- A class's role from the tree with the most points, or nil without talents
local function TalentRole(class, inspect)
    local trees = TalentTreeRoles[class]
    if not trees then return nil end
    local best, bestPoints = nil, 0
    for tab, role in ipairs(trees) do
        local points = PointsIn(tab, inspect)
        if points > bestPoints then best, bestPoints = role, points end
    end
    return best
end

-- The group's roles that pick blessings; damage dealers fall through
local GROUP_ROLES = { TANK = "tank", HEALER = "healer" }

-- A unit's role from the group finder, or from the raid roster's combat role
-- where the client has no group finder API
local function GroupRole(unit)
    if UnitGroupRolesAssigned then return GROUP_ROLES[UnitGroupRolesAssigned(unit)] end
    local index = tonumber(unit:match("^raid(%d+)$"))
    if index then return GROUP_ROLES[select(12, GetRaidRosterInfo(index)) or ""] end
    for i = 1, GetNumGroupMembers() do
        if UnitIsUnit("raid" .. i, unit) then
            return GROUP_ROLES[select(12, GetRaidRosterInfo(i)) or ""]
        end
    end
end

-- Roles seen from talent auras or Inspect, by GUID, for the session:
-- { role, source }. An aura can drop (a Feral leaving cat form), but the
-- talent behind it stays.
local roleByGUID = {}

-- Auras only a Druid's talents give: Moonkin for Balance, Leader of the Pack
-- for Feral. The auras also go on the Druid's party, so a Druid only counts
-- with their own.
local TALENT_AURAS = {
    { name = "Moonkin Form", role = "caster" },
    { name = "Moonkin Aura", role = "caster", own = true },
    { name = "Leader of the Pack", role = "melee", own = true },
}

-- A Druid's role from their talent auras. Party auras can't be read in
-- combat, so it waits until after.
local function AuraRole(unit, guid)
    if select(2, UnitClass(unit)) ~= "DRUID" or InCombatLockdown() then return nil end
    for _, talentAura in ipairs(TALENT_AURAS) do
        local aura = C_UnitAuras.GetAuraDataBySpellName(unit, BuffBot.SpellName(talentAura.name))
        if aura and (not talentAura.own or (aura.sourceUnit and UnitIsUnit(aura.sourceUnit, unit))) then
            roleByGUID[guid] = { role = talentAura.role, source = "aura" }
            return talentAura.role
        end
    end
end

--------------- INSPECT ----------------
-- The last layer, for hybrids nothing cheaper has placed: their talents, by
-- Inspect, one member at a time (docs/plan/SPEC.md "Inspect queue").

local INSPECT_INTERVAL = 1.5 -- seconds between inspects
local INSPECT_WAIT = 5 -- seconds to wait for INSPECT_READY before moving on
local INSPECT_TRIES = 3 -- inspects per member before giving up for the session

-- Specializations by ID, where the client has them
local SPEC_ROLES = {
    [102] = "caster", [103] = "melee", [104] = "tank", [105] = "healer",      -- Druid
    [262] = "caster", [263] = "melee", [264] = "healer",                      -- Shaman
    [65] = "healer", [66] = "tank", [70] = "melee",                           -- Paladin
    [71] = "melee", [72] = "melee", [73] = "tank",                            -- Warrior
}

local HYBRIDS = { DRUID = true, SHAMAN = true, PALADIN = true }

local tries = {} -- GUID -> inspects tried
local pending -- { guid, at } for the inspect waiting on INSPECT_READY
local inspecting = false -- the queue's timer is running

local function AnyMainTank()
    for i = 1, GetNumGroupMembers() do
        if GetPartyAssignment("MAINTANK", "raid" .. i) then return true end
    end
    return false
end

-- Inspecting only matters to a Paladin buffing the raid whose blessings
-- depend on role: anything but Kings' slot, or alone. Never in combat, and
-- never while the player has the Inspect window open.
local function MayInspect()
    if BuffBot.playerclass ~= "PALADIN" or not IsInRaid() or not BuffBot.config.GROUP_BUFFING
        or BuffBot.InPvP() or InCombatLockdown() then
        return false
    end
    if BuffBot.Coordinating() and BuffBot.MySlot() == "K" then return false end
    return not (InspectFrame and InspectFrame:IsShown())
end

-- Raid members still waiting to be inspected: hybrids, and Warriors when
-- nobody is marked main tank, whose role only comes from their class
local function Waiting()
    local units, tanksMarked = {}, nil
    for i = 1, GetNumGroupMembers() do
        local unit = "raid" .. i
        local class = select(2, UnitClass(unit))
        if class == "WARRIOR" and tanksMarked == nil then tanksMarked = AnyMainTank() end
        local guid = UnitGUID(unit)
        if guid and not UnitIsUnit(unit, "player") and (HYBRIDS[class] or (class == "WARRIOR" and not tanksMarked))
            and (tries[guid] or 0) < INSPECT_TRIES and select(2, BuffBot.RoleOf(unit)) == "class" then
            table.insert(units, unit)
        end
    end
    return units
end

local function StopInspect()
    if pending then ClearInspectPlayer() end
    pending = nil
end

-- One step of the queue: wait for an answer, or inspect the next member in
-- range. Stops when nobody in range is left; the next roster change or the
-- end of combat starts it again.
local function InspectStep()
    inspecting = false
    if not MayInspect() then return StopInspect() end
    if pending and GetTime() - pending.at < INSPECT_WAIT then
        inspecting = true
        return C_Timer.After(INSPECT_INTERVAL, InspectStep)
    end
    StopInspect()
    for _, unit in ipairs(Waiting()) do
        if CanInspect(unit) then
            local guid = UnitGUID(unit)
            tries[guid] = (tries[guid] or 0) + 1
            pending = { guid = guid, unit = unit, at = GetTime() }
            NotifyInspect(unit)
            inspecting = true
            return C_Timer.After(INSPECT_INTERVAL, InspectStep)
        end
    end
end

function BuffBot.StartInspecting()
    if inspecting or not MayInspect() then return end
    inspecting = true
    C_Timer.After(INSPECT_INTERVAL, InspectStep)
end

-- The answer to the queue's inspect, not to anyone else's
function BuffBot.InspectReady(guid)
    if not pending or guid ~= pending.guid then return end
    local unit = pending.unit
    local role = SPEC_ROLES[GetInspectSpecialization and GetInspectSpecialization(unit) or 0]
        or TalentRole(select(2, UnitClass(unit)), true)
    if role then roleByGUID[guid] = { role = role, source = "inspect" } end
    StopInspect()
    BuffBot.CheckPlayerBuffs()
end

-- How many members are waiting to be inspected
function BuffBot.InspectsWaiting()
    if not IsInRaid() then return 0 end
    return #Waiting()
end

-- Forgets the roles of members who left the raid, and inspects newcomers
function BuffBot.UpdateRoles()
    local present = {}
    for i = 1, GetNumGroupMembers() do
        local guid = UnitGUID("raid" .. i)
        if guid then present[guid] = true end
    end
    for guid in pairs(roleByGUID) do
        if not present[guid] then roleByGUID[guid] = nil end
    end
    for guid in pairs(tries) do
        if not present[guid] then tries[guid] = nil end
    end
    BuffBot.StartInspecting()
end

-- A unit's role and where it came from: the manual list, then the main-tank
-- mark and the group's role, then talent auras or Inspect, then the player's
-- own talents, then the class default
function BuffBot.RoleOf(unit)
    local manual = BuffBot.config.ROLES and BuffBot.config.ROLES[GetUnitName(unit, true) or ""]
    if manual then return manual, "manual" end
    if GetPartyAssignment("MAINTANK", unit) then return "tank", "mark" end
    local groupRole = IsInRaid() and GroupRole(unit)
    if groupRole then return groupRole, "group" end
    if IsInRaid() then
        local guid = UnitGUID(unit)
        local seen = guid and roleByGUID[guid]
        if seen then return seen.role, seen.source end
        local auraRole = guid and AuraRole(unit, guid)
        if auraRole then return auraRole, "aura" end
    end
    if UnitIsUnit(unit, "player") then
        local role = TalentRole(BuffBot.playerclass)
        if role then return role, "talents" end
    end
    return BuffBot.ClassDefaultRole[select(2, UnitClass(unit))], "class"
end

-- The raid members whose name contains text, ignoring case, as full names.
-- An exact match wins over partial ones.
local function MatchMembers(text, names)
    text = text:lower()
    local matches = {}
    for _, name in ipairs(names) do
        if name:lower() == text then return { name } end
        if name:lower():find(text, 1, true) then table.insert(matches, name) end
    end
    table.sort(matches)
    return matches
end

local function RaidNames()
    local names = {}
    if not IsInRaid() then return names end
    for i = 1, GetNumGroupMembers() do
        local name = GetUnitName("raid" .. i, true)
        if name then table.insert(names, name) end
    end
    return names
end

local USAGE = "BuffBot: /bb role <name> <tank|melee|ranged|caster|healer> sets a raid member's role; /bb role <name> clears it."

-- /bb role <name> [role]. Names are matched against the raid; clearing also
-- matches names saved earlier.
function BuffBot.RoleCommand(args)
    -- The last word is the role when it names one; the rest is the name
    local text, role = args:match("^(.-)%s+(%S+)$")
    role = role and role:lower()
    if not (role and BuffBot.RoleLists[role]) then text, role = args, "" end
    text = text:match("^%s*(.-)%s*$")
    if text == "" then return print(USAGE) end

    local names = RaidNames()
    if role == "" then
        for name in pairs(BuffBot.config.ROLES) do
            if not BuffBot.IndexOf(name, names) then table.insert(names, name) end
        end
    end
    local matches = MatchMembers(text, names)
    if #matches == 0 then
        return print("BuffBot: no raid member matches \"" .. text .. "\".")
    end
    if #matches > 1 then
        return print("BuffBot: \"" .. text .. "\" matches " .. table.concat(matches, ", ") .. ".")
    end

    local name = matches[1]
    if role == "" then
        BuffBot.config.ROLES[name] = nil
        print("BuffBot: " .. name .. "'s role is back to automatic.")
    else
        BuffBot.config.ROLES[name] = role
        print("BuffBot: " .. name .. " is " .. role .. ".")
    end
    BuffBot.CheckPlayerBuffs()
end
