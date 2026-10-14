# BuffBot TODO

Open work for the Forever branch. Tick items off as they land, and note the
commit.

## Later: group coverage

Design notes, for after the robustness work:

- Keep `UNIT_AURA` registered for all units. `RegisterUnitEvent` takes two
  units at most, so it can't cover a raid.
- In the handler: return in combat, accept only `player`, `partyN` and
  `raidN`, then mark a change and schedule one re-scan with `C_Timer.After`.
- `GROUP_ROSTER_UPDATE` also schedules a re-scan, since unit IDs shift when
  the roster changes. New members' auras arrive as `UNIT_AURA` for their
  unit.
- Re-scan with `GetAuraDataBySpellName` per unit. There's no need to track
  auras one by one.
- Buff the player first, then members in a fixed order, so pressing the
  button repeatedly buffs the group. Skip members who are dead, offline or
  out of range.
- Range: check `C_Spell.IsSpellInRange(spell, unit)` when picking a target,
  and on a slow out-of-combat check to notice range changes. It returns
  plain values in and out of combat. `UNIT_IN_RANGE_UPDATE` never fires on
  Forever, and `UnitInRange` only returns secret values.
- Raids: limit to your own party, or recommend the group versions that cost
  reagents.

## Feature ideas

- 18. Show only the current class's settings.
- 19. Button feedback: dim when unusable, tooltip, cooldown swipe.
- 20. Rogue poisons. Shaman imbues are done; poisons use the same check
  (`BuffBot.HasWeaponEnchant`, any temporary enchant counts), but they're
  items, not spells: the macro is `/use <poison>` then `/use 16`. Rogues
  dual wield, so the off hand (weapon slot 1) needs checking too.
- 26. Known issue: the first Rockbiter cast once needed a second press
  before the button moved on. Not reproduced since. A probe for
  `UNIT_INVENTORY_CHANGED` printed nothing, so the event may not always
  fire, or `C_Item.GetWeaponEnchantInfo` may lag behind it.
- 21. More Paladin buffs: Kings, Light, Sanctuary, Righteous Fury.
- 25. Size sliders for the icon and the text. The icon scales the 48px
  button (`SetSize`, out of combat only), and the text changes the font
  size of the suggestion list. Both use the game's own slider, with no
  library.

## Decided against

- **Timer-based refresh for expiring buffs.** `UNIT_AURA` fires often
  enough, and it fires when the buff drops, so the player is never left
  without it.
- **Limiting `UNIT_AURA` to the player.** Group coverage needs it wide, and
  the current cost is one string comparison per event.
- **Debouncing `GROUP_ROSTER_UPDATE` (14).** A rebuild only checks the
  player's own short buff list, so dozens of them while a raid fills cost
  nothing noticeable. The group coverage re-scan is scheduled with
  `C_Timer.After`, which covers it once rebuilds scan every member.

## Done

- [x] Fill in settings missing from an older saved config (`4ba4a0b`)
- [x] Re-check buffs on a full aura update outside a raid (`aa27924`)
- [x] Group range checks added to the probe table (`ffaeffe`)
- [x] Remove unused `groupHasChanged` flag (`234fb0b`)
- [x] Skip single-target buffs covered by their group version (`2665b83`)
- [x] Reset Button Position does nothing in combat (`23f2cb2`)
- [x] `/bb buffs` prints the list instead of using `DevTools_Dump` (`7a0a88f`)
- [x] Only the player's own Paladin aura counts (`7bc2b80`)
- [x] Save the button position without the anchor frame (`54af139`)
- [x] Check every spell's availability the same way, without `RanklessSpells` (`39eeb24`)
- [x] Load message reads the version from the TOC; the TOC title keeps its own copy for the add-on menu (`b94f3e8`)
- [x] Probe results filled in (`a65e3f7`)
- [x] Copy-paste slips: Strict Armor debug message (`6977911`) and the global `t` texture (`c1139e3`)
- [x] Chain Bloodrage and Battle Shout in one macro, and remove the cast handler (`3d780ad`)
- [x] Show Battle Shout without rage, tinted blue and kept in sync (`d3804e0`)
- [x] Hide the button when dead, a ghost or on a flight path (`a043b8c`)
- [x] Button stayed up on a flight path: re-check after the taxi state changes (`18aeb1d`)
- [x] Turn on luacheck's unused-variable warnings (`57415f3`)
- [x] Remove dead code, including the `PLAYER_LOGOUT` handler (`57415f3`, `b056b5f`)
- [x] Hide Icon, and Hide Text in place of Show Suggestion List (`3ec0e15`)
- [x] Suggestion list follows the button's skip rules (`8ba46a6`)
- [x] Use the client's spell names, looked up by ID (`f279f20`)
- [x] Shaman weapon imbues, with a setting to pick the imbue (`8254999`)
