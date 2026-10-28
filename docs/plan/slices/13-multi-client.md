# 13 - multi-client
Priority: MUST · Depends on: 11, 12 · Parallel-safe: no · Est: ~40 min
Requirements: R17

## Goal
Tests show independent clients end up with the same slots.

## Tasks
- Tests: new `tests/helpers/raid.lua`: N sandboxes from `Addon.load`, one shared roster (each sees the others as raid members with full names) and clock (advance all together), a bus that delivers each `RAID` send to every client incl. the sender on the next tick, the 10-message burst drop, per-client `math.random`.
- Tests: new `raid_sync_spec.lua`: form with 2; join a 3rd (split); 4th (L); 5th (reserve); leaves for every slot (reserve fills, shrink merges); simultaneous hellos; reload of one client; each ends with every client's view of slots identical and valid for the Paladin count.

## Acceptance criteria
- [ ] `export PATH="$HOME/.luarocks/bin:$PATH"; busted && luacheck .` passes
- [ ] Conventional Commit(s), split by concern

## Notes / risks
Cut line 2: stop here for coordination with class-default and manual roles.
