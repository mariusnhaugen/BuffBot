# 14 - detect-markers
Priority: SHOULD · Depends on: 04 · Parallel-safe: yes · Est: ~20 min
Requirements: R18

## Goal
Main-tank marked members are tanks without anyone typing `/bb role`.

## Tasks
- Code: `RoleOf` layer 2: `GetPartyAssignment("MAINTANK", unit)` → tank (source `"mark"`); a group-finder role if Forever's API has one (`UnitGroupRolesAssigned`), guarded by existence.
- Tests: mock `GetPartyAssignment`; manual list wins over the mark; the mark wins over the class default.

## Acceptance criteria
- [ ] `export PATH="$HOME/.luarocks/bin:$PATH"; busted && luacheck .` passes
- [ ] Conventional Commit(s), split by concern

## Notes / risks
None.
