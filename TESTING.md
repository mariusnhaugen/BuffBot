# Testing BuffBot

## Automated

Requires Lua 5.1, [busted](https://lunarmodules.github.io/busted/) and [luacheck](https://github.com/lunarmodules/luacheck).

```sh
sudo apt install lua5.1 liblua5.1-dev luarocks
luarocks --local --lua-version=5.1 install busted
luarocks --local --lua-version=5.1 install luacheck
export PATH="$HOME/.luarocks/bin:$PATH"

luacheck .   # flags WoW API globals that don't exist on the target client
busted       # scenario specs
```

The specs load the addon files in TOC order into a sandbox backed by a fake
game state (`tests/mocks/state.lua`), with the Forever API mocked in
`tests/mocks/api_forever.lua`. Specs only describe behaviour, never API
calls, so they are unchanged from the Classic build and prove the port
behaves the same.

## Forever client probe

Results decided how the port handles spell ranks. Run on the Forever beta with
`/console scriptErrors 1`, and fill in the results.

| Check | Command | Result |
|---|---|---|
| Interface number | `/dump select(4, GetBuildInfo())` | `16001` |
| Rank 1 lookup by ID | `/dump C_Spell.GetSpellInfo(465)` | Returns the spell info on a Warrior: ID lookups resolve spells the player doesn't know |
| Lookup by name | `/dump C_Spell.GetSpellInfo("Devotion Aura")` | `nil` |
| Battle Shout by ID | `/dump C_Spell.GetSpellInfo(6673)` | Returns the spell info, with `spellID` 6673 (rank 1, same as Classic) |
| Battle Shout by name | `/dump C_Spell.GetSpellInfo("Battle Shout")` | Returns the spell info, with `spellID` 5242 (the learned rank 2, same as Classic) |
| Rank 1 ID known with a higher rank learned | `/dump IsPlayerSpell(6673)` | `false`: rank 1 ID not known once a higher rank is learned (same as Classic) |
| Name lookup for an unknown spell (run on a Warrior) | `/dump C_Spell.GetSpellInfo("Devotion Aura")` | `nil` (empty result): name lookups only resolve spells in the spellbook (same as Classic) |
| Usable with no rage | `/dump C_Spell.IsSpellUsable("Battle Shout")` | `false, true`: not usable, and the reason is insufficient power (same as Classic `IsUsableSpell`) |
| Removed globals | `/dump GetSpellInfo, IsUsableSpell, GetSpellTexture` | All three are `nil` |
| Old checkbox template | `/run local ok, f = pcall(CreateFrame, "CheckButton", nil, UIParent, "InterfaceOptionsCheckButtonTemplate") print(ok, ok and f.Text)` | `true`, table: the template exists and has a `.Text` label |
| Retribution Aura by ID | `/dump C_Spell.GetSpellInfo(7294)` | |
| Aura lookup with the buff on: needs `duration`, `expirationTime` and `isFromPlayerOrPlayerPet` | `/dump C_UnitAuras.GetAuraDataBySpellName("player", "<buff name>")` | |
| Aura lookup without the buff: should be `nil` | `/dump C_UnitAuras.GetAuraDataBySpellName("player", "<buff you don't have>")` | |
| `UNIT_AURA` payload | `/run local f = CreateFrame("Frame") f:RegisterUnitEvent("UNIT_AURA", "player") f:SetScript("OnEvent", function(_, _, u, info) print(u, info and info.isFullUpdate, info and info.removedAuraInstanceIDs ~= nil) end)`, then gain and lose a buff | |
| Settings panel | `/bb` with BuffBot loaded | |
| Keybind | Bind "BuffBot Cast" under Key Bindings > AddOns and press it once with a buff missing | |
