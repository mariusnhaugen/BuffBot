-- luacheck is used here to catch calls to WoW API globals that don't exist on
-- the target client, and unused variables. Other style warnings are off; the
-- port copies code as-is.
std = "lua51"
max_line_length = false
self = false -- event handlers are methods that don't use self
ignore = { "3..", "4..", "5..", "6.." }
exclude_files = { ".luarocks", "lua_modules", ".vscode" }

-- Globals the addon defines.
globals = {
    "SlashCmdList",
    "SLASH_BUFFBOTSETTINGS1",
    "SLASH_BUFFBOTSETTINGS2",
    "BuffBotConfig",
    "BuffBotCharConfig",
}

-- WoW API available on the Forever client. GetSpellInfo, GetSpellTexture and
-- IsUsableSpell are removed there, so they are deliberately not listed.
read_globals = {
    "C_AddOns",
    "C_ChatInfo",
    "C_Item",
    "C_Spell",
    "C_Timer",
    "C_UnitAuras",
    "CanInspect",
    "ClearInspectPlayer",
    "CastSpellByID",
    "CreateFrame",
    "CreateSettingsButtonInitializer",
    "CreateSettingsListSectionHeaderInitializer",
    "GetInspectSpecialization",
    "GetInventoryItemID",
    "GetLocale",
    "GetNumGroupMembers",
    "GetNumSubgroupMembers",
    "GetPartyAssignment",
    "GetRaidRosterInfo",
    "GetTalentTabInfo",
    "GetTime",
    "GetUnitName",
    "InCombatLockdown",
    "InspectFrame",
    "IsAltKeyDown",
    "IsInGroup",
    "IsInInstance",
    "IsInRaid",
    "IsPlayerSpell",
    "issecretvalue",
    "LE_PARTY_CATEGORY_HOME",
    "NotifyInspect",
    "LOCALIZED_CLASS_NAMES_MALE",
    "Settings",
    "UIParent",
    "UnitClass",
    "UnitCastingInfo",
    "UnitChannelInfo",
    "UnitExists",
    "UnitGroupRolesAssigned",
    "UnitGUID",
    "UnitInRaid",
    "UnitIsConnected",
    "UnitIsDeadOrGhost",
    "UnitIsUnit",
    "UnitIsVisible",
    "UnitLevel",
    "UnitName",
    "UnitOnTaxi",
}

files["tests/"] = { std = "+busted" }
