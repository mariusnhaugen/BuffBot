# BuffBot TODO

Open work for the Forever branch. Tick items off as they land, and note the
commit.

## Robustness: wrong decisions in groups

- [ ] **3. Suggestion list disagrees with the button.** `FilterSuggestionList`
  (`Interface.lua`) checks only whether each buff is present, not
  `ShouldSkipBuff`. It can show Mark of the Wild under Gift of the Wild, or
  Hawk while in Monkey.

## Robustness: errors and misbehaviour

- [ ] **8. Button shows when buffing is impossible:** dead, ghost, on a taxi.
  Handle `PLAYER_DEAD`, `PLAYER_ALIVE`, `PLAYER_UNGHOST` and check
  `UnitOnTaxi`.

## Port

- [ ] **10. English-only spell names.** Lookups, macros and the suggestion list
  use English names, so other client languages break. Use the spell ID
  table as the source of truth and resolve names with
  `C_Spell.GetSpellInfo(id).name`.
  The icon lookup (`C_Spell.GetSpellTexture` in `UpdateMacro`) also uses
  the name, so the button keeps the previous spell's icon on those
  clients. Looking it up by ID fixes both.

## Cleanup

- [ ] **15. Dead code:** `RecommendOtherPaladinBuff` and its commented caller,
  `HIDE_ICON`, `BuffBot.DEBUG_MODE`, `playername`, `playerlevel`, the
  `PLAYER_LOGOUT` handler, and `if #BuffBot.suggestionList then` (always
  true).
- [ ] **16. Turn on luacheck's unused-variable warnings.** `.luacheckrc`
  ignores 2xx–6xx.

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
- 20. Weapon enchants with `GetWeaponEnchantInfo`: Rogue poisons, Shaman
  imbues.
- 21. More Paladin buffs: Kings, Light, Sanctuary, Righteous Fury.

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
