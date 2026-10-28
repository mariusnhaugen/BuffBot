# 12 - reload-restore
Priority: MUST · Depends on: 10 · Parallel-safe: yes · Est: ~20 min
Requirements: R16

## Goal
A `/reload` mid-raid keeps your slot.

## Tasks
- Code: save the slot in `BuffBotCharConfig.SLOT` on change; on `PLAYER_ENTERING_WORLD` with `isReloadingUi` and `IsInRaid()`, the hello carries it; clear it on login (not a reload) and on leaving the raid.
- Tests: reload with `W` → `BB?:v1:W`; login → `BB?:v1:-` and the save cleared; stale save collides with a holder → gives way and re-announces; leaving the raid clears it.

## Acceptance criteria
- [x] `export PATH="$HOME/.luarocks/bin:$PATH"; busted && luacheck .` passes
- [x] Conventional Commit(s), split by concern

## Notes / risks
None.
