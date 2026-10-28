# 15 - detect-auras
Priority: SHOULD · Depends on: 14 · Parallel-safe: yes · Est: ~25 min
Requirements: R19

## Goal
Moonkins and Leader-of-the-Pack Ferals are detected from their auras.

## Tasks
- Code: `RoleOf` layer 3: Moonkin Form/Aura on the member → caster; Leader of the Pack with `sourceUnit` = that Druid → melee; cache by `UnitGUID` for the session (source `"aura"`); read only out of combat; drop entries for members who left.
- Tests: Moonkin aura → caster; Leader of the Pack from another Druid doesn't mark this one; Cat Form alone doesn't; cache survives the aura dropping.

## Acceptance criteria
- [x] `export PATH="$HOME/.luarocks/bin:$PATH"; busted && luacheck .` passes
- [x] Conventional Commit(s), split by concern

## Notes / risks
Which auras are still talent-only on Forever is a launch check.
