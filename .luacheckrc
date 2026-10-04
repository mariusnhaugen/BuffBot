-- luacheck is used here to catch calls to WoW API globals that don't exist on
-- the target client. Style warnings are off; the port copies code as-is.
std = "lua51"
max_line_length = false
ignore = { "2..", "3..", "4..", "5..", "6.." }
exclude_files = { ".luarocks", "lua_modules", ".vscode" }

-- Globals the addon defines.
globals = {
    "SlashCmdList",
    "SLASH_BUFFBOTSETTINGS1",
    "SLASH_BUFFBOTSETTINGS2",
    "BuffBotConfig",
    "BuffBotDump",
}

-- WoW API available on the Forever client. GetSpellInfo, GetSpellTexture and
-- IsUsableSpell are removed there, so they are deliberately not listed.
read_globals = {
    "C_Spell",
    "C_UnitAuras",
    "CreateFrame",
    "DevTools_Dump",
    "GetTime",
    "GetUnitName",
    "InCombatLockdown",
    "IsAltKeyDown",
    "IsInGroup",
    "IsInRaid",
    "IsPlayerSpell",
    "LE_PARTY_CATEGORY_HOME",
    "Settings",
    "UIParent",
    "UnitClass",
    "UnitInRaid",
    "UnitLevel",
}

files["tests/"] = { std = "+busted" }
