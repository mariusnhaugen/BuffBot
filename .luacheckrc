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

-- WoW API available on every client the addon targets.
local wow_common = {
    "C_UnitAuras",
    "CreateFrame",
    "DevTools_Dump",
    "GetTime",
    "GetUnitName",
    "InCombatLockdown",
    "IsAltKeyDown",
    "IsInGroup",
    "IsInRaid",
    "IsPetActive",
    "IsPlayerSpell",
    "IsSpellKnownOrOverridesKnown",
    "LE_PARTY_CATEGORY_HOME",
    "Settings",
    "UIParent",
    "UnitClass",
    "UnitInRaid",
    "UnitLevel",
}

-- Globals removed on the retail client (and so on Forever).
local wow_classic_only = {
    "GetSpellInfo",
    "GetSpellTexture",
    "IsUsableSpell",
}

local read = {}
for _, name in ipairs(wow_common) do table.insert(read, name) end
for _, name in ipairs(wow_classic_only) do table.insert(read, name) end
read_globals = read

files["tests/"] = { std = "+busted" }
