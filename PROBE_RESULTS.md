# Forever client probe results

Finished probes from [TESTING.md](TESTING.md), run on the Forever beta.
The results decided how the port handles each API.

## Interface number

`/dump select(4, GetBuildInfo())`

Result:
`16001`

## Rank 1 lookup by ID

`/dump C_Spell.GetSpellInfo(465)`

Result:
Returns the spell info on a Warrior: ID lookups resolve spells the player doesn't know

## Lookup by name

`/dump C_Spell.GetSpellInfo("Devotion Aura")`

Result:
`nil`

## Battle Shout by ID

`/dump C_Spell.GetSpellInfo(6673)`

Result:
Returns the spell info, with `spellID` 6673 (rank 1, same as Classic)

## Battle Shout by name

`/dump C_Spell.GetSpellInfo("Battle Shout")`

Result:
Returns the spell info, with `spellID` 5242 (the learned rank 2, same as Classic)

## Rank 1 ID known with a higher rank learned

`/dump IsPlayerSpell(6673)`

Result:
`false`: rank 1 ID not known once a higher rank is learned (same as Classic)

## Name lookup for an unknown spell (run on a Warrior)

`/dump C_Spell.GetSpellInfo("Devotion Aura")`

Result:
`nil` (empty result): name lookups only resolve spells in the spellbook (same as Classic)

## Usable with no rage

`/dump C_Spell.IsSpellUsable("Battle Shout")`

Result:
`false, true`: not usable, and the reason is insufficient power (same as Classic `IsUsableSpell`)

## Removed globals

`/dump GetSpellInfo, IsUsableSpell, GetSpellTexture`

Result:
All three are `nil`

## Old checkbox template

`/run local ok, f = pcall(CreateFrame, "CheckButton", nil, UIParent, "InterfaceOptionsCheckButtonTemplate") print(ok, ok and f.Text)`

Result:
`true`, table: the template exists and has a `.Text` label

## Add-on metadata

Should print `2.0.1`.

`/dump C_AddOns.GetAddOnMetadata("BuffBot", "Version")`

Result:
`2.0.1`

## Retribution Aura by ID

`/dump C_Spell.GetSpellInfo(7294)`

Result:
Returns the spell info

## Aura lookup with the buff on

Needs `duration`, `expirationTime` and `isFromPlayerOrPlayerPet`.

`/dump C_UnitAuras.GetAuraDataBySpellName("player", "<buff name>")`

Result:
Returns the aura data, with `duration`, `expirationTime` and `isFromPlayerOrPlayerPet` all present

## Aura lookup without the buff

Should be `nil`.

`/dump C_UnitAuras.GetAuraDataBySpellName("player", "<buff you don't have>")`

Result:
`nil`

## `UNIT_AURA` payload

`/run local f = CreateFrame("Frame") f:RegisterUnitEvent("UNIT_AURA", "player") f:SetScript("OnEvent", function(_, _, u, info) print(u, info and info.isFullUpdate, info and info.removedAuraInstanceIDs ~= nil) end)`, then gain and lose a buff

Result:
`player false false` on gain, `player false true` on loss: not a full update, and `removedAuraInstanceIDs` is only set when an aura goes

## Dropdown template

The menu-based dropdown should exist, so settings can use it instead of the taint-prone `UIDropDownMenu`.

`/dump MenuUtil ~= nil, Menu ~= nil` and `/run local ok, err = pcall(CreateFrame, "DropdownButton", nil, UIParent, "WowStyle1DropdownTemplate") print(ok, err)`

Result:
`true` for all three

## Settings panel

`/bb` with BuffBot loaded

Result:
The settings panel opens

## Keybind

Bind "BuffBot Cast" under Key Bindings > AddOns and press it once with a buff missing

Result:
The binding is listed and casts the missing buff

## Holy buff in Shadowform

Cast Power Word: Fortitude while in Shadowform

Result:
Castable: casting it takes you out of Shadowform, so BuffBot shouldn't skip it

## Caster buff in a Druid form

Cast Mark of the Wild while in Cat or Bear Form

Result:
Castable: casting it takes you out of the form, so BuffBot shouldn't skip it

## Own-aura filter

Should return the aura with your own aura on, and `nil` with only another Paladin's.

`/dump C_UnitAuras.GetAuraDataBySpellName("player", "Devotion Aura", "HELPFUL|PLAYER")`

Result:
Returns the aura with your own Devotion Aura on, and `nil` with only another Paladin's

## Cast followed by `UNIT_AURA`

If `UNIT_AURA player` prints for each buff cast, the re-check after every cast is redundant and the cast event can be Warrior-only.

`/run local f = CreateFrame("Frame") f:RegisterUnitEvent("UNIT_AURA", "player") f:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player") f:SetScript("OnEvent", function(_, e, u) print(GetTime(), e, u) end)`, then cast a buff BuffBot tracks, and refresh one you already have

Result:
`UNIT_AURA player` prints after both the new cast and the refresh

## Button anchor after a drag

Alt-drag the BuffBot button, then `/dump BUFFBOT_MacroButton:GetPoint()`

Result:
`"CENTER", nil, "CENTER", 301.67, 261.67`: no relative frame, so the old anchor frame is gone

## Saved button position

After the drag above, `/reload`, then `/dump BuffBotConfig.buttonPosition`, and check the button is where you left it

Result:
The position is saved and the button is where it was left

## Range event, for group coverage (in a party)

`/run local f = CreateFrame("Frame") local ok, err = pcall(f.RegisterEvent, f, "UNIT_IN_RANGE_UPDATE") print("registered:", ok, err) if ok then f:SetScript("OnEvent", function(_, _, u, r) print(u, r) end) end`, then walk out of and back into range of a party member

Result:
`registered: true`, but nothing printed when crossing 40 yards either way

## Group range check (in a party)

`/dump UnitInRange("party1")` near a party member, then again far away

Result:
`<secret>: true, <secret>: true` within 40 yards, `<secret>: false, <secret>: true` beyond it: the range is checked, but both values are always secrets

## Group range secret check (in a party, out of combat)

`/run local r = UnitInRange("party1") print(issecretvalue and issecretvalue(r))`, then `/run local r = UnitInRange("party1") print(pcall(function() if r then return "readable" end return "readable" end))`

Result:
`true`, then `false` with "attempt to perform boolean test on upvalue 'r' (a secret boolean value, while execution tainted by '*** ForceTaint_Strong ***')": `UnitInRange` is secret even out of combat, and add-on code can't branch on it

## Spell range check (in a party)

`/dump C_Spell.IsSpellInRange("<buff spell>", "party1")` near a party member, then again far away

Result:
`true` near, `false` far, as plain values (not secrets), in and out of combat

## Bloodrage then Battle Shout (Warrior, "Always try Bloodrage out of combat" on)

With Battle Shout missing and no rage, the first press out of combat should cast Bloodrage. The second press should cast Battle Shout. Bloodrage does not start combat on Forever.

Press the BuffBot button twice

Result:
First press casts Bloodrage, second casts Battle Shout. In combat the button hides and the keybind gives plain Battle Shout with no "Not ready yet"

Why the option ignores rage: rage drains without an event, so a macro picked by the current rage goes stale. Bloodrage is always tried first out of combat, and the next press falls through to Battle Shout. The Bloodrage line is `[nocombat]`, so keybind presses in combat don't error on its cooldown.

## Button when dead or a ghost

With a buff missing, die, release, then resurrect. The button should hide on death, stay hidden as a ghost, and come back once alive.

`/dump UnitIsDeadOrGhost("player")` at each step

Result:
Hides on death, stays hidden as a ghost, comes back once alive

## Button on a flight path

With a buff missing, take a flight path. The button should hide on takeoff and come back on landing. If it stays up, check whether `PLAYER_CONTROL_LOST` fires on takeoff.

`/run local f = CreateFrame("Frame") f:RegisterEvent("PLAYER_CONTROL_LOST") f:RegisterEvent("PLAYER_CONTROL_GAINED") f:SetScript("OnEvent", function(_, e) print(e, UnitOnTaxi("player")) end)`, then fly

Result:
The control events fire before `UnitOnTaxi` changes (the probe prints `PLAYER_CONTROL_LOST false` on takeoff), so the button stayed up all flight. With the re-check delayed by half a second (`18aeb1d`), it hides on takeoff and comes back on landing

## Spell IDs added for client names

Should print each spell's name: Gift of the Wild, Arcane Brilliance, Prayer of Fortitude, Prayer of Spirit, Greater Blessing of Might, Greater Blessing of Wisdom, Aspect of the Monkey, Wild, Beast, Cheetah and Pack, then Frost, Shadow and Fire Resistance Aura. A `nil` means a wrong ID.

`/run for _, id in ipairs({21849, 23028, 21562, 27681, 25782, 25894, 13163, 20043, 13161, 5118, 13159, 19888, 19876, 19891}) do local i = C_Spell.GetSpellInfo(id) print(id, i and i.name) end`

Result:
All 14 IDs resolve to the expected names

## Non-English client (German)

Log in on a German client with buffs missing. The button should cast each buff, move on once it lands, and hide when fully buffed. The suggestion list should show German names. With a group buff on you, its single-target version should be skipped.

Press the BuffBot button until fully buffed

Result:
Casts work with the German names, the button moves on as buffs land, and the suggestion list shows German names. Group versions untested: the beta is capped below the level for group buffs.

## Weapon enchant lookup

`GetWeaponEnchantInfo` returns `false` for add-ons, and `C_PaperDollInfo.GetTemporaryEnchantmentInfo` returns nothing (it's Blizzard-only). `C_Item.GetWeaponEnchantInfo(0)` works: it returns one entry per enchant type on the main hand.

`/dump C_Item.GetWeaponEnchantInfo(0)` with and without Rockbiter Weapon

Result:
Without: both entries have `hasEnchant=false`. With Rockbiter: the second entry has `hasEnchant=true`, `enchantType=3` (Imbue), `enchantID=29` and `timeLeft` in ms (an hour on Forever). `UNIT_INVENTORY_CHANGED` fires when it lands and when it drops.

The numbers in `BuffBot.lua` come from the client enums. The argument is `Enum.WeaponSlot`: 0 main hand, 1 off hand, 2 ranged. `enchantType` is `Enum.ItemEnchantType`: 2 is Temporary (oils, stones and poisons) and 3 is Imbue (Shaman). Permanent enchants don't count. Poisons need both numbers per hand: `invSlot` (16, 17) for `GetInventoryItemID` and `/use`, and `weaponSlot` (0, 1) for `C_Item.GetWeaponEnchantInfo`.

## Shaman imbue IDs

Should print Rockbiter Weapon, Flametongue Weapon, Frostbrand Weapon and Windfury Weapon.

`/run for _, id in ipairs({8017, 8024, 8033, 8232}) do local i = C_Spell.GetSpellInfo(id) print(id, i and i.name) end`

Result:
All four IDs resolve to the expected names

## Shaman imbue on the button

With no weapon enchant, the button should offer Rockbiter Weapon (after Lightning Shield, if that's missing). Once it lands, the button should move on. Removing it should bring it back. An oil or stone should also count, and with no main-hand weapon the imbue shouldn't be offered.

Press the BuffBot button, then right-click the enchant icon by your buffs to remove it

Result:
Rockbiter Weapon is offered, the button moves on once it lands, and removing it brings it back. No main-hand weapon: not offered. A weightstone also counts: Rockbiter Weapon is no longer offered with it on. It reports `enchantType=2`, `charges=0` and `timeLeft` of 30 minutes, in the *first* entry of `C_Item.GetWeaponEnchantInfo(0)` (Rockbiter was in the second), so the entries aren't in a fixed order

## Poison item IDs

Should print each poison's name by rank: Instant Poison to Instant Poison VI, Deadly Poison to V, Crippling Poison and II, Mind-numbing Poison to III, and Wound Poison to IV. A `nil` can also mean the item isn't cached yet, so run it twice.

`/run for _, id in ipairs({6947, 6949, 6950, 8926, 8927, 8928, 2892, 2893, 8984, 8985, 20844, 3775, 3776, 5237, 6951, 9186, 10918, 10920, 10921, 10922}) do print(id, C_Item.GetItemNameByID(id)) end`

Result:
All 20 IDs resolve to the expected names and ranks

## Item API (Rogue, with a poison in the bags)

`C_Item.GetItemCount`, `C_Item.GetItemNameByID` and `C_Item.GetItemIconByID` should exist and return the count, the client's name and an icon.

`/dump C_Item.GetItemCount(6947), C_Item.GetItemNameByID(6947), C_Item.GetItemIconByID(6947)`

Result:
Checked on a Shaman with a Rough Weightstone (3239) instead: `2`, `"Rough Weightstone"`, `135255`. All three calls exist and work

## Item on a weapon by macro

The poison macro uses an item by ID, then picks the weapon: one press should apply it. Checked with a weightstone, which is applied the same way.

A macro with `/use item:3239` and `/use 16`, with a Rough Weightstone in the bags

Result:
One press applies the weightstone to the main hand after the cast

## Weapon dropdowns in the settings

The Shaman imbue and the two Rogue poison dropdowns should show the chosen option, list the client's names, and change the button as soon as an option is picked. Check they fit above the footer.

`/bb`, then pick an option in each dropdown

Result:
Each shows the chosen option and lists the right names, picking one changes the button straight away, and they fit above the footer

## Old template tooltips

`InterfaceOptionsCheckButtonTemplate` and `UIPanelButtonTemplate` with `tooltipText`, `tooltipRequirement` or `newbieText` set, hovered in the settings panel

Result:
No tooltip: the templates don't read these fields on Forever. Fixed with `OnEnter`/`OnLeave` scripts that use `GameTooltip` (`38cd20b`)

## Settings API functions

`/dump Settings.RegisterVerticalLayoutCategory ~= nil, Settings.RegisterAddOnSetting ~= nil, Settings.CreateCheckbox ~= nil, Settings.CreateDropdown ~= nil`

Result:
`true`, `true`, `true`, `true`

## Settings API checkbox

A vertical-layout category with one add-on setting bound to a table, and a checkbox for it:

`/run BBc=Settings.RegisterVerticalLayoutCategory("BBProbe") BBt={} BBs=Settings.RegisterAddOnSetting(BBc,"BBPROBE_X","X",BBt,Settings.VarType and Settings.VarType.Boolean or "boolean","Probe box",false) print(BBs)`, then `/run Settings.CreateCheckbox(BBc,BBs,"Probe tooltip") Settings.RegisterAddOnCategory(BBc) Settings.OpenToCategory(BBc:GetID())`. Hover over the checkbox, tick it, then `/dump BBt.X`

Result:
`RegisterAddOnSetting` takes the 11.0 arguments (category, variable, key, table, type, name, default) and returns a setting. The page opens with the checkbox, hovering shows "Probe tooltip", and ticking it sets `BBt.X` to `true`

## Settings API initializers

`/dump CreateSettingsButtonInitializer ~= nil, CreateSettingsListSectionHeaderInitializer ~= nil`

Result:
`true`, `true`: a vertical layout can hold the Reset Button Position button and the class headings

## Righteous Fury ID

`/run local i = C_Spell.GetSpellInfo(25780) print(25780, i and i.name)`

Result:
Prints Righteous Fury: 25780 is the right ID on Forever

## Settings page on the Settings API

`/bb`, then hover and change each setting (checkboxes and both weapon dropdowns), press Reset Button Position in and out of combat, and `/reload`

Result:
Every control shows its tooltip and changes the button straight away, so `setting:SetValueChangedCallback` fires. The dropdowns built with `Settings.CreateControlTextContainer` work, and the Class Settings header and the Reset button show through `layout:AddInitializer`. Reset is refused in combat. The values survive `/reload`

## Hide Text kept from 2.1.0

Tick Hide Text on 2.1.0 and log out, then install 2.2 and open `/bb`

Result:
Hide Text is still ticked: the `SUGGESTION_LIST` to `HIDE_TEXT` migration keeps the 2.1.0 setting

## Settings shown predicate

`/run local i=CreateSettingsListSectionHeaderInitializer("x") print(i.AddShownPredicate ~= nil)`

Result:
`true`: initializers can be hidden per player, for the tracking dropdown (27) and class-only settings (18)

## Tracking as an aura

With Find Minerals on: `/run for i=1,40 do local a=C_UnitAuras.GetAuraDataByIndex("player",i) if a then print(i,a.spellId,a.name) end end`, then the same with Find Treasure on as well (Dwarf)

Result:
The tracker is listed as a player aura, so the add-on can check it like any other buff. Find Treasure and Find Minerals both show, as separate auras

## Tracking texture

`/dump GetTrackingTexture and GetTrackingTexture()`

Result:
`nil`: `GetTrackingTexture` doesn't exist on Forever. Not needed, since tracking is an aura

## Tracking cast without a key press

With tracking off: `/run C_Timer.After(3,function() CastSpellByID(2383) end)`

Result:
Tracking comes on: `CastSpellByID` isn't blocked for tracking spells, so add-on code can turn tracking on from an event, without the button. The cast triggers a global cooldown, so a second tracker (Find Treasure for Dwarves) has to wait for it to end

## Tracking cast in combat

With tracking off: `/run C_Timer.After(5,function() print("combat:",InCombatLockdown()) CastSpellByID(2580) end)`, then pull a mob

Result:
Tracking comes on in combat. It also showed 18 errors, `EventFunctions.lua:5: attempt to perform boolean test on field 'isFullUpdate' (a secret boolean value, while execution tainted by 'BuffBot')`: in combat, `UNIT_AURA` payloads can be secret. The handler read `isFullUpdate` before checking the unit; it now returns for other units first, and checks `issecretvalue` for the player

## Tracking spell IDs

Each should print its name: Track Beasts, Humanoids, Undead, Hidden, Elementals, Demons, Giants, Dragonkin.

`/run for _,i in ipairs({1494,19883,19884,19885,19880,19878,19882,19879}) do local s=C_Spell.GetSpellInfo(i) print(i,s and s.name) end`

Result:
All eight print their names, in order: the Classic IDs are right on Forever

## Cast checks used by tracking

Should print `true true true` and then a table with `startTime` and `duration`.

`/run print(UnitCastingInfo~=nil, UnitChannelInfo~=nil, C_Spell.GetSpellCooldown~=nil)`, then `/dump C_Spell.GetSpellCooldown(2580)`

Result:
`true true true`, and `GetSpellCooldown` returns a table with `startTime` and `duration`

## Does death drop tracking

With tracking on, die, release and run back. Is tracking still on before BuffBot casts it? Run with BuffBot disabled, or read the chat for a cast.

Result:
Yes: tracking is off after death, and BuffBot puts it back

## Tracking on login and after a res

On a gatherer, `/reload` with tracking off: it should come on. Die and run back: it should come on after you're alive. Turning it off by hand should stick. Then spam an ability straight after a res: tracking should still come on, without "Spell is not ready yet" errors.

Result:
Comes on after `/reload` and after a res, stays off when turned off by hand, and comes on while spamming an ability after a res, with no errors

## Tracking dropdown

`/bb`: the Tracking dropdown should list "Default (…)", only the trackers this character knows, and Off. Picking one should switch tracking straight away. Log on another character: its own choice, not this one's. `/reload`: the choice is kept.

Result:
Lists Default, only the character's trackers, and Off. Picking switches straight away, each character keeps its own choice, and it survives `/reload`

## Find Treasure (Dwarf)

On a Dwarf gatherer, `/reload` with tracking off: the gathering tracker comes on, then Find Treasure about 1.5 seconds later.

Result:
The gathering tracker comes on, then Find Treasure after the global cooldown
