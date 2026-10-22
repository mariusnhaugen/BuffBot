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

From WSL, `./deploy.sh` copies the addon into the `_classic_beta_` (Forever)
AddOns folder. Run it after each change and `/reload`; restart the client
for new files or TOC changes.

Results decided how the port handles spell ranks. Run on the Forever beta with
`/console scriptErrors 1`, and fill in the results. Once a probe has a result,
move it to [PROBE_RESULTS.md](PROBE_RESULTS.md).

### Poison enchant lookup (Rogue, dual wielding)

Off hand is weapon slot 1. A poison should report `enchantType=2` (Temporary) with `charges` counting down as it procs.

`/dump C_Item.GetWeaponEnchantInfo(0), C_Item.GetWeaponEnchantInfo(1)` with Instant Poison on each hand, then again after a few hits

Result:

### Rogue poisons on the button

With Instant Poison in the bags and nothing on the weapons, one press should apply it to the main hand (a 3-second cast), and the next press to the off hand. Removing a poison, or running low on charges, should bring it back. With none in the bags, the button should skip poisons, and buying some should bring them back.

Press the BuffBot button, then right-click the poison icons by your buffs to remove them

Result:

### Righteous Fury on the button (Paladin)

With "Recommend Righteous Fury" ticked, the button should offer Righteous Fury after the blessing.

Tick the setting in `/bb`, then press the BuffBot button until the blessing is up

Result:

### No aura errors in combat

`UNIT_AURA` payloads can be secret in combat. The handler should now ignore other units' payloads, and the button should keep updating in combat.

Fight a mob that puts a debuff on you, with `/console scriptErrors 1`, and let a buff run out or cast one mid-fight

Result:

### Reagent Economy detection

BuffBot looks for the Legacy talent by name, as a known spell or as an aura on the player. One of these should find it; note its spell ID so the lookup can go by ID, which works in every client language.

`/dump C_Spell.GetSpellInfo("Reagent Economy")`, then `/dump C_UnitAuras.GetAuraDataBySpellName("player","Reagent Economy")`

Result:

### Group buffing on the button (in a party)

The button buffs you, then each member who is missing the buff and in range, and the text shows their name. Warriors and Rogues never get Arcane Intellect or Divine Spirit. A member out of range drops off the list and comes back within a couple of seconds of walking back. No errors in combat.

Result:

### Group versions and reagents (at the level of the group buffs)

Untestable while the beta is capped. With two or more party members missing a buff and the reagent in the bags (or Reagent Economy), the button casts the group version on the first of them, and it covers the party. Without either it casts single-target. The reagent check takes any reagent for the buff, so a rank 2 caster holding only the rank 1 reagent (Wild Berries, Holy Candle) may get "Missing reagent".

Result:

### Tracking in battlegrounds and combat

Die in a battleground: nothing is cast there. Tracking comes back on after leaving. Get resurrected in combat: tracking waits until combat ends.

Result:
