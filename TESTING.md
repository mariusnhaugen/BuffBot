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
game state (`tests/mocks/state.lua`). The WoW API surface the addon sees is
chosen with `BUFFBOT_API=classic|forever` (default set in
`tests/helpers/load_addon.lua`). Specs only describe behaviour, never API
calls, so the same specs prove the Classic and Forever builds behave alike.

## Forever client probe

Results decide how the port handles spell ranks. Run on the Forever beta with
`/console scriptErrors 1`, and fill in the results.

| Check | Command | Result |
|---|---|---|
| Interface number | `/dump select(4, GetBuildInfo())` | |
| Rank 1 lookup by ID | `/dump C_Spell.GetSpellInfo(465)` | |
| Lookup by name | `/dump C_Spell.GetSpellInfo("Devotion Aura")` | |
| Battle Shout by ID | `/dump C_Spell.GetSpellInfo(6673)` | |
| Battle Shout by name | `/dump C_Spell.GetSpellInfo("Battle Shout")` | |
| Rank 1 ID known with a higher rank learned | `/dump IsPlayerSpell(6673)` | |
| Usable with no rage | `/dump C_Spell.IsSpellUsable("Battle Shout")` | |
| Removed globals | `/dump GetSpellInfo, IsUsableSpell, GetSpellTexture` | |
| Old checkbox template | `/run CreateFrame("CheckButton", nil, UIParent, "InterfaceOptionsCheckButtonTemplate")` | |
