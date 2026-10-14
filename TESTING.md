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
`/console scriptErrors 1`, and fill in the results.

### Interface number

`/dump select(4, GetBuildInfo())`

Result:
`16001`

### Rank 1 lookup by ID

`/dump C_Spell.GetSpellInfo(465)`

Result:
Returns the spell info on a Warrior: ID lookups resolve spells the player doesn't know

### Lookup by name

`/dump C_Spell.GetSpellInfo("Devotion Aura")`

Result:
`nil`

### Battle Shout by ID

`/dump C_Spell.GetSpellInfo(6673)`

Result:
Returns the spell info, with `spellID` 6673 (rank 1, same as Classic)

### Battle Shout by name

`/dump C_Spell.GetSpellInfo("Battle Shout")`

Result:
Returns the spell info, with `spellID` 5242 (the learned rank 2, same as Classic)

### Rank 1 ID known with a higher rank learned

`/dump IsPlayerSpell(6673)`

Result:
`false`: rank 1 ID not known once a higher rank is learned (same as Classic)

### Name lookup for an unknown spell (run on a Warrior)

`/dump C_Spell.GetSpellInfo("Devotion Aura")`

Result:
`nil` (empty result): name lookups only resolve spells in the spellbook (same as Classic)

### Usable with no rage

`/dump C_Spell.IsSpellUsable("Battle Shout")`

Result:
`false, true`: not usable, and the reason is insufficient power (same as Classic `IsUsableSpell`)

### Removed globals

`/dump GetSpellInfo, IsUsableSpell, GetSpellTexture`

Result:
All three are `nil`

### Old checkbox template

`/run local ok, f = pcall(CreateFrame, "CheckButton", nil, UIParent, "InterfaceOptionsCheckButtonTemplate") print(ok, ok and f.Text)`

Result:
`true`, table: the template exists and has a `.Text` label

### Add-on metadata

Should print `2.0.1`.

`/dump C_AddOns.GetAddOnMetadata("BuffBot", "Version")`

Result:
`2.0.1`

### Retribution Aura by ID

`/dump C_Spell.GetSpellInfo(7294)`

Result:
Returns the spell info

### Aura lookup with the buff on

Needs `duration`, `expirationTime` and `isFromPlayerOrPlayerPet`.

`/dump C_UnitAuras.GetAuraDataBySpellName("player", "<buff name>")`

Result:
Returns the aura data, with `duration`, `expirationTime` and `isFromPlayerOrPlayerPet` all present

### Aura lookup without the buff

Should be `nil`.

`/dump C_UnitAuras.GetAuraDataBySpellName("player", "<buff you don't have>")`

Result:
`nil`

### `UNIT_AURA` payload

`/run local f = CreateFrame("Frame") f:RegisterUnitEvent("UNIT_AURA", "player") f:SetScript("OnEvent", function(_, _, u, info) print(u, info and info.isFullUpdate, info and info.removedAuraInstanceIDs ~= nil) end)`, then gain and lose a buff

Result:
`player false false` on gain, `player false true` on loss: not a full update, and `removedAuraInstanceIDs` is only set when an aura goes

### Settings panel

`/bb` with BuffBot loaded

Result:
The settings panel opens

### Keybind

Bind "BuffBot Cast" under Key Bindings > AddOns and press it once with a buff missing

Result:
The binding is listed and casts the missing buff

### Holy buff in Shadowform

Cast Power Word: Fortitude while in Shadowform

Result:
Castable: casting it takes you out of Shadowform, so BuffBot shouldn't skip it

### Caster buff in a Druid form

Cast Mark of the Wild while in Cat or Bear Form

Result:
Castable: casting it takes you out of the form, so BuffBot shouldn't skip it

### Own-aura filter

Should return the aura with your own aura on, and `nil` with only another Paladin's.

`/dump C_UnitAuras.GetAuraDataBySpellName("player", "Devotion Aura", "HELPFUL|PLAYER")`

Result:
Returns the aura with your own Devotion Aura on, and `nil` with only another Paladin's

### Cast followed by `UNIT_AURA`

If `UNIT_AURA player` prints for each buff cast, the re-check after every cast is redundant and the cast event can be Warrior-only.

`/run local f = CreateFrame("Frame") f:RegisterUnitEvent("UNIT_AURA", "player") f:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player") f:SetScript("OnEvent", function(_, e, u) print(GetTime(), e, u) end)`, then cast a buff BuffBot tracks, and refresh one you already have

Result:
`UNIT_AURA player` prints after both the new cast and the refresh

### Button anchor after a drag

Alt-drag the BuffBot button, then `/dump BUFFBOT_MacroButton:GetPoint()`

Result:
`"CENTER", nil, "CENTER", 301.67, 261.67`: no relative frame, so the old anchor frame is gone

### Saved button position

After the drag above, `/reload`, then `/dump BuffBotConfig.buttonPosition`, and check the button is where you left it

Result:
The position is saved and the button is where it was left

### Range event, for group coverage (in a party)

`/run local f = CreateFrame("Frame") local ok, err = pcall(f.RegisterEvent, f, "UNIT_IN_RANGE_UPDATE") print("registered:", ok, err) if ok then f:SetScript("OnEvent", function(_, _, u, r) print(u, r) end) end`, then walk out of and back into range of a party member

Result:
`registered: true`, but nothing printed when crossing 40 yards either way

### Group range check (in a party)

`/dump UnitInRange("party1")` near a party member, then again far away

Result:
`<secret>: true, <secret>: true` within 40 yards, `<secret>: false, <secret>: true` beyond it: the range is checked, but both values are always secrets

### Group range secret check (in a party, out of combat)

`/run local r = UnitInRange("party1") print(issecretvalue and issecretvalue(r))`, then `/run local r = UnitInRange("party1") print(pcall(function() if r then return "readable" end return "readable" end))`

Result:
`true`, then `false` with "attempt to perform boolean test on upvalue 'r' (a secret boolean value, while execution tainted by '*** ForceTaint_Strong ***')": `UnitInRange` is secret even out of combat, and add-on code can't branch on it

### Spell range check (in a party)

`/dump C_Spell.IsSpellInRange("<buff spell>", "party1")` near a party member, then again far away

Result:
`true` near, `false` far, as plain values (not secrets), in and out of combat

### Bloodrage then Battle Shout (Warrior, "Always try Bloodrage out of combat" on)

With Battle Shout missing and no rage, the first press out of combat should cast Bloodrage. The second press should cast Battle Shout. Bloodrage does not start combat on Forever.

Press the BuffBot button twice

Result:
First press casts Bloodrage, second casts Battle Shout. In combat the button hides and the keybind gives plain Battle Shout with no "Not ready yet"

### Button when dead or a ghost

With a buff missing, die, release, then resurrect. The button should hide on death, stay hidden as a ghost, and come back once alive.

`/dump UnitIsDeadOrGhost("player")` at each step

Result:
Hides on death, stays hidden as a ghost, comes back once alive

### Button on a flight path

With a buff missing, take a flight path. The button should hide on takeoff and come back on landing. If it stays up, check whether `PLAYER_CONTROL_LOST` fires on takeoff.

`/run local f = CreateFrame("Frame") f:RegisterEvent("PLAYER_CONTROL_LOST") f:RegisterEvent("PLAYER_CONTROL_GAINED") f:SetScript("OnEvent", function(_, e) print(e, UnitOnTaxi("player")) end)`, then fly

Result:
The control events fire before `UnitOnTaxi` changes (the probe prints `PLAYER_CONTROL_LOST false` on takeoff), so the button stayed up all flight. With the re-check delayed by half a second (`18aeb1d`), it hides on takeoff and comes back on landing

### Spell IDs added for client names

Should print each spell's name: Gift of the Wild, Arcane Brilliance, Prayer of Fortitude, Prayer of Spirit, Greater Blessing of Might, Greater Blessing of Wisdom, Aspect of the Monkey, Wild, Beast, Cheetah and Pack, then Frost, Shadow and Fire Resistance Aura. A `nil` means a wrong ID.

`/run for _, id in ipairs({21849, 23028, 21562, 27681, 25782, 25894, 13163, 20043, 13161, 5118, 13159, 19888, 19876, 19891}) do local i = C_Spell.GetSpellInfo(id) print(id, i and i.name) end`

Result:
All 14 IDs resolve to the expected names

### Non-English client (German)

Log in on a German client with buffs missing. The button should cast each buff, move on once it lands, and hide when fully buffed. The suggestion list should show German names. With a group buff on you, its single-target version should be skipped.

Press the BuffBot button until fully buffed

Result:
Casts work with the German names, the button moves on as buffs land, and the suggestion list shows German names. Group versions untested: the beta is capped below the level for group buffs.

### Weapon enchant lookup

`GetWeaponEnchantInfo` returns `false` for add-ons, and `C_PaperDollInfo.GetTemporaryEnchantmentInfo` returns nothing (it's Blizzard-only). `C_Item.GetWeaponEnchantInfo(0)` works: it returns one entry per enchant type on the main hand.

`/dump C_Item.GetWeaponEnchantInfo(0)` with and without Rockbiter Weapon

Result:
Without: both entries have `hasEnchant=false`. With Rockbiter: the second entry has `hasEnchant=true`, `enchantType=3` (Imbue), `enchantID=29` and `timeLeft` in ms (an hour on Forever). `UNIT_INVENTORY_CHANGED` fires when it lands and when it drops.

### Shaman imbue IDs

Should print Rockbiter Weapon, Flametongue Weapon, Frostbrand Weapon and Windfury Weapon.

`/run for _, id in ipairs({8017, 8024, 8033, 8232}) do local i = C_Spell.GetSpellInfo(id) print(id, i and i.name) end`

Result:
All four IDs resolve to the expected names

### Shaman imbue on the button

With no weapon enchant, the button should offer Rockbiter Weapon (after Lightning Shield, if that's missing). Once it lands, the button should move on. Removing it should bring it back. An oil or stone should also count, and with no main-hand weapon the imbue shouldn't be offered.

Press the BuffBot button, then right-click the enchant icon by your buffs to remove it

Result:
Rockbiter Weapon is offered, the button moves on once it lands, and removing it brings it back. No main-hand weapon: not offered. Oils and stones untested, so `enchantType=2` is still unconfirmed
