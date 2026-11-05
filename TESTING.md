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

From WSL, `./deploy.sh` copies the addon into the `_forever_`
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

### Oath of Light (Holy Paladin, 2.5.2)

A Holy Paladin with the Oath of Light talent (spell 1328548, from Wowhead) keeps their Oath on one group member, never themselves, and never in a battleground or alone. The button puts it on the main tank, or a member set to `tank` with `/bb role`. With no tank, in a dungeon or raid only, it offers "Oath of Light > Target" last, cast on whoever you have targeted. After that it stays on whoever you put it on: it's offered again on them in its last minute or once it's gone, never on someone else while they're in the group, even if they're dead.

1. In a raid, mark a Warrior as main tank: the button offers Oath of Light on them, before any raid blessings. Check that `/dump IsPlayerSpell(1328548)` prints `true` with the talent and `false` without it.
2. Cast it on a Priest yourself. The button doesn't offer to move it to the tank. Right-click it off the Priest: the button offers it on the Priest again.
3. With "Buff your group" off, the Oath is still offered.
4. In a dungeon party without a tank, the list ends with "Oath of Light > Target" (and outside an instance, the Oath isn't offered at all). Pressing the button with nothing targeted, an enemy, or a dead member targeted casts nothing (no error, no Oath on you). With a party member targeted, it lands on them, and the button then keeps it there.
5. Assumptions to confirm: it lasts 5 minutes, casting it on a new target moves it there (the old one loses it), and two Paladins' Oaths both stay on one target.
6. Passed on the live servers (2026-11-05). On any character, `/dump C_Spell.GetSpellInfo(1328548).name` prints `Oath of Light`. The ID is from Wowhead; if it's wrong, the talent is never found and the Oath is never offered, with no error.
7. In a party with your Oath on party1, `/dump C_UnitAuras.GetAuraDataBySpellName("party1", "Oath of Light", "HELPFUL|PLAYER") ~= nil` prints `true`, and `false` when only another Paladin's Oath is on them. The button finds its target by this.

Result:

### Group buffing on the button (in a party)

The button buffs you, then each member who is missing the buff and in range, and the text shows their name. Warriors and Rogues never get Arcane Intellect or Divine Spirit. A member out of range drops off the list and comes back within a couple of seconds of walking back. No errors in combat.

Result:
Works as a Paladin with a Rogue in the party: the button offers Blessing of Might on them. Still to check: a caster class (Arcane Intellect skipping a Warrior or Rogue), walking out of and back into range, and combat

### Paladin blessings on the party

Blessing of Might on Warriors and Rogues, Blessing of Kings on Hunters and Paladins (level 20+; Wisdom before that), Blessing of Wisdom on everyone else, and your own blessing from the "Paladin blessing on yourself" dropdown. An old "Recommend Blessing of Wisdom" setting should carry over as Wisdom. Blessings last 60 minutes on Forever, so they're only due again when a member drops one or has under 5 minutes left. A member with another Paladin's blessing isn't buffed again.

Result:
A Rogue in the party gets Blessing of Might. A tester's Paladin on 2.3 got Kings offered for a Hunter and Wisdom for a Shaman and a Warlock: "does exactly what's needed". Still to check: the dropdown and the old setting carrying over

### Raid blessings (2.5, at level 60)

Needs a raid, and for sharing, two to four Paladins on BuffBot 2.5 (`/bb debug` on prints the messages). See [docs/plan/SPEC.md](docs/plan/SPEC.md) for the rules.

- Alone in a raid: Greater Blessings per class (with Symbol of Kings or Reagent Economy), singles for a class of one, nothing for members with every blessing on their list from other Paladins. The text under the button reads "Greater Blessing of Wisdom > Priests".
- Two Paladins: one gives Kings, the other Might or Wisdom by role; `/bb raid` agrees on both clients. A third joining splits Might and Wisdom; one leaving merges them back. A `/reload` keeps your slot.
- Roles: `/bb role <name> melee` on a Druid switches them to Might; a main-tank mark makes a tank; Moonkin Form and Leader of the Pack are picked up; Inspect fills in the rest without opening the Inspect window or fighting it.
- Battlegrounds: only you are buffed.

Result:

### Raid blessing handovers (2.5, at level 60)

Needs a raid with three BuffBot 2.5 Paladins (call them Ann, Bob and Cid, sorted by name) and a Warrior, plus a fourth for the reserve check. Turn `/bb debug` on everywhere: it prints each message sent. `/bb raid` shows who holds which slot. Expect Ann Kings, Bob Wisdom, Cid Might.

1. **Goodbye.** Bob turns "Buff your group" off in `/bb`. Bob's chat shows `BB!:v1:-`. Within a second, Ann's and Cid's `/bb raid` drops Bob, and Cid takes Might and Wisdom. Bob turns it back on: Bob sends `BB?:v1:-` and gets a slot back, and the others agree on the slots.
2. **Reserve.** A fourth Paladin joins and waits as a reserve: their button shows no raid blessings, only self-buffs and auras. When a Paladin with a slot leaves, the reserve takes it.
3. **Kings from a Paladin who left.** With the Warrior wearing Ann's Kings, Ann leaves the raid. Cid takes Kings and Bob takes Might and Wisdom. First, on Cid, `/dump C_UnitAuras.GetAuraDataBySpellName("raidN", "Greater Blessing of Kings").sourceUnit` for the Warrior's unit prints `nil` or something other than a raid unit. Cid's button doesn't offer another blessing for the Warrior while Ann's Kings is up, and offers Kings once it runs out (right-click it off the Warrior to skip the wait).
4. **Might from before a slot change.** Back to three. Cid's Might is on the Warrior. Cid leaves: Bob now holds Might and Wisdom, and isn't offered anything for the Warrior while Cid's Might is up. Then Cid rejoins and gets Might back. If Bob's blessing went on the Warrior meanwhile, Cid waits for it to run out too.
5. **Joining straight away.** Invite a Paladin who already has BuffBot: within about 2 seconds of them joining, everyone's `/bb raid` lists them with a slot, without a `/reload`.
6. **Two Paladins on one slot.** Hard to force. If `/bb raid` ever shows two Paladins with the same slot, the first by name sends its state again (`BB:v1:<slot>` in its chat) and the other moves within a second.

No Lua errors throughout (`/console scriptErrors 1`).

Result:

### Group versions and reagents (at the level of the group buffs)

Untestable while the beta is capped. With two or more party members missing a buff and the reagent in the bags (or Reagent Economy), the button casts the group version on the first of them, and it covers the party. Without either it casts single-target. The reagent check takes any reagent for the buff, so a rank 2 caster holding only the rank 1 reagent (Wild Berries, Holy Candle) may get "Missing reagent".

Result:

### Tracking in battlegrounds and combat

Die in a battleground: nothing is cast there. Tracking comes back on after leaving. Get resurrected in combat: tracking waits until combat ends.

Result:

## Test at launch

Checks that can't be run on the beta, or are still waiting for a tester. The steps are in each check above. Tick one off once it has passed on the live servers, and write its result above.

- [ ] [Poison enchant lookup](#poison-enchant-lookup-rogue-dual-wielding): needs a dual-wielding Rogue
- [ ] [Rogue poisons on the button](#rogue-poisons-on-the-button): the same Rogue, with poisons in the bags
- [ ] [Group versions and reagents](#group-versions-and-reagents-at-the-level-of-the-group-buffs): Gift of the Wild, Arcane Brilliance, Prayer of Fortitude and Prayer of Spirit need level 48 to 60, above the beta's cap of 30. Includes Reagent Economy being detected by its spell ID
- [ ] [Tracking in battlegrounds and combat](#tracking-in-battlegrounds-and-combat): dying in a battleground and getting resurrected in combat
- [ ] Two Paladins, for blessing sharing: both cast Blessing of Might on the same target (does the second replace the first, or fail?), and `C_UnitAuras.GetAuraDataBySpellName("party1", "Blessing of Might", "HELPFUL|PLAYER")` returns `nil` when only the other Paladin's Might is on party1. Different Paladins' blessings stacking on one target is assumed, as in Classic
- [ ] Someone else's fading buff isn't offered: with another Mage's Arcane Intellect on you or a party member, the button stays quiet until it drops off, then offers it
- [ ] Two Paladins sharing blessings in a party: the second Paladin is offered Kings for a Warrior who has the first one's Might, and both blessings stay up

For 2.5 (raid coordination, `docs/plan/SPEC.md`). Run in a raid unless noted; Greater Blessings need level 60.

- [ ] Add-on messages on `RAID`: `C_ChatInfo.SendAddonMessage("BuffBot", "x", "RAID")` reaches every member, the sender included, and `CHAT_MSG_ADDON` gives the sender as "First Last" with channel `RAID`. The burst limit is 10 per prefix, refilling at 1 per second, as on PARTY
- [ ] Sends in combat: does `select(-1, C_ChatInfo.SendAddonMessage(...))` return `11` (`AddOnMessageLockdown`) in combat inside a raid instance, and in the open world?
- [ ] Offline members: `UNIT_CONNECTION` fires with the raid unit when a member goes offline and comes back
- [ ] Main tank: `GetPartyAssignment("MAINTANK", unit)` is true after marking a member from the raid frame
- [ ] Raid roster: `GetRaidRosterInfo(i)` gives the right subgroup, class and `online`; does `combatRole` (12th return) or `UnitGroupRolesAssigned(unit)` ever return `TANK` or `HEALER`?
- [ ] Specs: do `GetSpecialization()` and, after Inspect, `GetInspectSpecialization(unit)` return a spec on Forever's talent trees? If not, `GetTalentTabInfo(tab)` for your own talents and `GetTalentTabInfo(tab, true)` after `NotifyInspect` and `INSPECT_READY` give the points per tab
- [ ] Talent-only auras: Moonkin Form (and its aura on the party) only comes from the Balance talent, and Leader of the Pack only from the Feral talent, with `sourceUnit` being that Druid
- [ ] Greater Blessings: they cover every raid member of the target's class (not just the subgroup), reach 40 yd, last 60 minutes, and replace the same Paladin's single blessing on that class
- [ ] Two Paladins' blessings stacking in a raid: different blessings from two Paladins both stay on one member
- [ ] Blessings from a Paladin who left: after a Paladin leaves the raid, `/dump C_UnitAuras.GetAuraDataBySpellName("raid1", "Blessing of Kings").sourceUnit` on a member with their Kings prints `nil` or a unit outside the raid (such as a nameplate), never a raid unit. The new Kings holder relies on it to wait for the old Kings to run out
- [ ] Goodbye: with three BuffBot Paladins, one turns "Buff your group" off; the others' `/bb raid` drops them and the slots close up. Turning it back on brings them back with a slot
- [ ] [Raid blessings](#raid-blessings-25-at-level-60): the in-game run of 2.5 with two to four Paladins
- [ ] [Raid blessing handovers](#raid-blessing-handovers-25-at-level-60): goodbye, reserves, waiting out an old holder's blessing, a joiner the roster doesn't show yet, and two Paladins on one slot
- [x] [Spell and item IDs for raid roles and Greater Blessings](PROBE_RESULTS.md#spell-and-item-ids-for-raid-roles-and-greater-blessings): Moonkin Form, Moonkin Aura, Leader of the Pack, Symbol of Kings
- [ ] [Oath of Light](#oath-of-light-holy-paladin-252): the spell ID (step 6) passed; the rest needs a Holy Paladin who has the talent
- [ ] Sanctuary is gone from Forever (TODO 21)
- [x] Settings page text (2.6.1): `/bb` shows "/bb or /buffbot opens this page. Alt+drag to move button. /bb help for more commands." in a small font at the very top, not overlapping the keybind row, and with no Lua error. `/bb help` lists the commands
- [x] `/bb status` (2.6): prints the version, class and level, list, and next cast or why it's quiet, with no Lua error; with `/bb debug` on, casting a buff logs one "next:" line. In a party of 5 it names members ("Arcane Intellect on Oblivion Au")
- [x] Keybind on the settings page ([result](PROBE_RESULTS.md#keybind-on-the-settings-page-26)): `/dump C_KeyBindings.GetBindingIndex("CLICK BUFFBOT_MacroButton:LeftButton")` prints a number, and `/bb` shows a BuffBot Cast keybind row at the top. Set a key there: it casts, shows under Key Bindings > AddOns, and survives `/reload`. If the row is missing or broken, fall back to a button that calls `SetBindingClick` and `SaveBindings` (TODO 35)
- [ ] Battlegrounds, for a later PvP release: which channel (`RAID` or `INSTANCE_CHAT`) reaches a battleground raid
