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

- Alone in a raid: Greater Blessings per class (with Symbol of Kings or Reagent Economy), singles for a class of one, Light for members with every blessing on their list from other Paladins. The text under the button reads "Greater Blessing of Wisdom > Priests".
- Two Paladins: one gives Kings, the other Might or Wisdom by role; `/bb raid` agrees on both clients. A third joining splits Might and Wisdom; one leaving merges them back. A `/reload` keeps your slot.
- Roles: `/bb role <name> melee` on a Druid switches them to Might; a main-tank mark makes a tank; Moonkin Form and Leader of the Pack are picked up; Inspect fills in the rest without opening the Inspect window or fighting it.
- Battlegrounds: only you are buffed.

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

For 2.5 (raid coordination, `docs/plan/SPEC.md`). Run in a raid unless noted; Greater Blessings and Light need level 60.

- [ ] Add-on messages on `RAID`: `C_ChatInfo.SendAddonMessage("BuffBot", "x", "RAID")` reaches every member, the sender included, and `CHAT_MSG_ADDON` gives the sender as "First Last" with channel `RAID`. The burst limit is 10 per prefix, refilling at 1 per second, as on PARTY
- [ ] Sends in combat: does `select(-1, C_ChatInfo.SendAddonMessage(...))` return `11` (`AddOnMessageLockdown`) in combat inside a raid instance, and in the open world?
- [ ] Offline members: `UNIT_CONNECTION` fires with the raid unit when a member goes offline and comes back
- [ ] Main tank: `GetPartyAssignment("MAINTANK", unit)` is true after marking a member from the raid frame
- [ ] Raid roster: `GetRaidRosterInfo(i)` gives the right subgroup, class and `online`; does `combatRole` (12th return) or `UnitGroupRolesAssigned(unit)` ever return `TANK` or `HEALER`?
- [ ] Specs: do `GetSpecialization()` and, after Inspect, `GetInspectSpecialization(unit)` return a spec on Forever's talent trees? If not, `GetTalentTabInfo(tab)` for your own talents and `GetTalentTabInfo(tab, true)` after `NotifyInspect` and `INSPECT_READY` give the points per tab
- [ ] Talent-only auras: Moonkin Form (and its aura on the party) only comes from the Balance talent, and Leader of the Pack only from the Feral talent, with `sourceUnit` being that Druid
- [ ] Greater Blessings: they cover every raid member of the target's class (not just the subgroup), reach 40 yd, last 60 minutes, and replace the same Paladin's single blessing on that class
- [ ] Light: Blessing of Light (19977) and Greater Blessing of Light (25890) are the right IDs, and Light stacks with Might, Wisdom and Kings from other Paladins
- [ ] Two Paladins' blessings stacking in a raid: different blessings from two Paladins both stay on one member
- [ ] [Raid blessings](#raid-blessings-25-at-level-60): the in-game run of 2.5 with two to four Paladins
- [ ] Sanctuary is gone from Forever (TODO 21)
- [ ] Keybind on the settings page: `/dump C_KeyBindings.GetBindingIndex("CLICK BUFFBOT_MacroButton:LeftButton")` prints a number, and `/bb` shows a BuffBot Cast keybind row at the top. Set a key there: it casts, shows under Key Bindings > AddOns, and survives `/reload`. If the row is missing or broken, fall back to a button that calls `SetBindingClick` and `SaveBindings` (TODO 35)
- [ ] Battlegrounds, for a later PvP release: which channel (`RAID` or `INSTANCE_CHAT`) reaches a battleground raid
