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

-- Points spent in one of the player's talent trees. Classic Era returns them
-- third; later clients return an ID first and the points fifth.
local function PointsIn(tab)
    local _, _, third, _, fifth = GetTalentTabInfo(tab)
    if type(third) == "number" then return third end
    return fifth or 0
end

-- The player's role from the tree with the most points, or nil without talents
local function TalentRole()
    local trees = TalentTreeRoles[BuffBot.playerclass]
    if not trees then return nil end
    local best, bestPoints = nil, 0
    for tab, role in ipairs(trees) do
        local points = PointsIn(tab)
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
    for i = 1, GetNumGroupMembers() do
        if UnitIsUnit("raid" .. i, unit) then
            return GROUP_ROLES[select(12, GetRaidRosterInfo(i)) or ""]
        end
    end
end

-- Roles seen from talent auras, by GUID, for the session. An aura can drop
-- (a Feral leaving cat form), but the talent behind it stays.
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
local function AuraRole(unit)
    if select(2, UnitClass(unit)) ~= "DRUID" then return nil end
    local guid = UnitGUID(unit)
    if roleByGUID[guid] then return roleByGUID[guid] end
    if InCombatLockdown() then return nil end
    for _, talentAura in ipairs(TALENT_AURAS) do
        local aura = C_UnitAuras.GetAuraDataBySpellName(unit, BuffBot.SpellName(talentAura.name))
        if aura and (not talentAura.own or (aura.sourceUnit and UnitIsUnit(aura.sourceUnit, unit))) then
            roleByGUID[guid] = talentAura.role
            return talentAura.role
        end
    end
end

-- Forgets the roles of members who left the raid
function BuffBot.UpdateRoles()
    local present = {}
    for i = 1, GetNumGroupMembers() do
        local guid = UnitGUID("raid" .. i)
        if guid then present[guid] = true end
    end
    for guid in pairs(roleByGUID) do
        if not present[guid] then roleByGUID[guid] = nil end
    end
end

-- A unit's role and where it came from: the manual list, then the main-tank
-- mark and the group's role, then talent auras, then the player's own
-- talents, then the class default
function BuffBot.RoleOf(unit)
    local manual = BuffBot.config.ROLES and BuffBot.config.ROLES[GetUnitName(unit, true) or ""]
    if manual then return manual, "manual" end
    if GetPartyAssignment("MAINTANK", unit) then return "tank", "mark" end
    local groupRole = IsInRaid() and GroupRole(unit)
    if groupRole then return groupRole, "group" end
    local auraRole = IsInRaid() and AuraRole(unit)
    if auraRole then return auraRole, "aura" end
    if UnitIsUnit(unit, "player") then
        local role = TalentRole()
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
