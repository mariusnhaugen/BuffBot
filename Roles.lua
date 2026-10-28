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

-- A unit's role and where it came from
function BuffBot.RoleOf(unit)
    return BuffBot.ClassDefaultRole[select(2, UnitClass(unit))], "class"
end
