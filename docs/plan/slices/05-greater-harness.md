# 05 - greater-harness
Priority: MUST · Depends on: 03 · Parallel-safe: yes · Est: ~20 min
Requirements: R8

## Goal
The test harness models Greater Blessings landing on a whole class, so the raid Greater slice can be tested.

## Tasks
- Tests: `Harness:landsOn` (`tests/helpers/load_addon.lua`): in a raid, a Greater Blessing reaches every alive, connected, in-range raid member of the target's class (all subgroups) and the player if the same class; other group versions keep the subgroup rule.
- Code: Symbol of Kings (21177) as the reagent for the four Greater Blessings in `reagents` (`ClassBuffList.lua`); the item in `tests/mocks/items.lua`.
- Tests: `CastableGroupVersion("Blessing of Wisdom")` needs Greater learned and Symbol of Kings or Reagent Economy.

## Acceptance criteria
- [ ] `export PATH="$HOME/.luarocks/bin:$PATH"; busted && luacheck .` passes
- [ ] Conventional Commit(s), split by concern

## Notes / risks
Greater rules on Forever (class-wide, 40 yd) are a launch check.
