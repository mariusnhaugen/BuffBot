# BuffBot TODO

Open work for the Forever branch. Tick items off as they land, and note the
commit.

## Robustness: wrong decisions in groups

- [ ] **3. Suggestion list disagrees with the button.** `FilterSuggestionList`
  (`Interface.lua`) checks only whether each buff is present, not
  `ShouldSkipBuff`. It can show Mark of the Wild under Gift of the Wild,
  Hawk while in Monkey, or Battle Shout with no rage.

## Robustness: errors and misbehaviour

- [ ] **6. Saved button position stores a frame object.**
  `{ macroButton:GetPoint() }` saves the anchor frame, which saved
  variables can't store properly. Probe: the button rows in
  `TESTING.md`. Fix: save point, offsets and the
  frame's name, and anchor to `UIParent` on load.
- [ ] **7. Stale icon.** `UpdateMacro` keeps the previous icon when
  `C_Spell.GetSpellTexture` returns nil.
- [ ] **8. Button shows when buffing is impossible:** dead, ghost, on a taxi.
  Handle `PLAYER_DEAD`, `PLAYER_ALIVE`, `PLAYER_UNGHOST` and check
  `UnitOnTaxi`.
- [ ] **9. Battle Shout lookup can error.** `UNIT_SPELLCAST_SUCCEEDED` indexes
  `C_Spell.GetSpellInfo(6673).name` without a nil check, and runs for every
  class on every cast. Limit it to Warriors and cache the result.

## Port

- [ ] **10. English-only spell names.** Lookups, macros and the suggestion list
  use English names, so other client languages break. Use the spell ID
  table as the source of truth and resolve names with
  `C_Spell.GetSpellInfo(id).name`.
- [ ] **11. Replace `RanklessSpells`.** "Rank 1 name by ID, then check the name
  resolves" works for every spell, and would remove the Paladin/Warrior
  branch in `CheckSpellAvailable`.
- [ ] **12. Finish the probe table in `TESTING.md`.** Aura data fields,
  `UNIT_AURA` payload, settings panel, keybind and the group range rows
  are still blank.
- [ ] **13. One version number.** It's hard-coded in the TOC version, the TOC
  title and the load message. Read it with `C_AddOns.GetAddOnMetadata`.

## Performance

- [ ] **14. Debounce `GROUP_ROSTER_UPDATE`.** It rebuilds the whole list on
  every roster change. Rebuild once, about 0.3s after the last change, with
  `C_Timer.After`.

## Cleanup

- [ ] **15. Dead code:** `RecommendOtherPaladinBuff` and its commented caller,
  `BuffBotDump`, `HIDE_ICON`, `BuffBot.DEBUG_MODE`, `playername`,
  `playerlevel`, the `PLAYER_LOGOUT` handler, and
  `if #BuffBot.suggestionList then` (always true).
- [ ] **16. Turn on luacheck's unused-variable warnings.** `.luacheckrc`
  ignores 2xx–6xx.
- [ ] **17. Copy-paste slips:** the Strict Armor checkbox logs "Dampen changed"
  (`Config.lua`), and `CreateTexture("t", ...)` creates a global `t`
  (`Interface.lua`).

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
- Range: check `C_Spell.IsSpellInRange(spell, unit)` when picking a target.
  For noticing when range changes, use `UNIT_IN_RANGE_UPDATE` if the
  Forever probe shows it exists, otherwise `UnitInRange` on a slow
  out-of-combat check.
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

## Done

- [x] Fill in settings missing from an older saved config (`4ba4a0b`)
- [x] Re-check buffs on a full aura update outside a raid (`aa27924`)
- [x] Group range checks added to the probe table (`ffaeffe`)
- [x] Remove unused `groupHasChanged` flag (`234fb0b`)
- [x] Skip single-target buffs covered by their group version (`2665b83`)
- [x] Reset Button Position does nothing in combat (`23f2cb2`)
- [x] `/bb buffs` prints the list instead of using `DevTools_Dump` (`7a0a88f`)
- [x] Only the player's own Paladin aura counts (`7bc2b80`)

## Shelf

Worked out, but parked for now.

### 22. Bloodrage

Bloodrage puts the player in combat, which locks the secure button. The
macro stays on `/cast Bloodrage` and the button hides until combat ends.

Plan: when Bloodrage is recommended, set the macro out of combat to
`/cast Bloodrage` followed by `/cast Battle Shout`, so the next press falls
through to Battle Shout without changing anything in combat. Don't hide
the button on combat entry when the macro includes Bloodrage. Fall back to
plain Battle Shout when Bloodrage is already on cooldown. This removes the
`classBuffs` insertion and `BLOODRAGE_LOCKED`.

### 23. Alt-drag also casts

Alt-dragging the button runs its macro, so moving it casts the buff.

Plan: drag with the right mouse button (optionally Alt+right-drag). Only
left click casts (`type1`), and keybinds always send `LeftButton`, so a
right-drag can never cast. Update the drag hint in the settings panel and
the load message.

Rejected: `[nomod:alt]` in the macro breaks Alt keybinds such as Alt+3.
A separate keybind button name works, but players would have to set the
keybind again.
