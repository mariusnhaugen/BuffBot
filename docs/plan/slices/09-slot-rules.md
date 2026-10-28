# 09 - slot-rules
Priority: MUST · Depends on: 08 · Parallel-safe: yes · Est: ~40 min
Requirements: R13

## Goal
The slot rules exist as one pure function every client runs identically.

## Tasks
- Code: new `Coordination.lua` (in `BuffBot.toc`): `BuffBot.NextSlot(me, mySlot, peers, event)` returning your new slot, where `peers` is name → announced slot and `event` is `settle`, `peerLeft(name, slot)` or `claim(name, slot)`. Covers: fresh assignment by name sort, sticky newcomer, MW split (holder keeps W), collisions (holder keeps it), reserves, Q29 shrink merges, 4+ → L, 2 → 1 drops coordination.
- Tests: new `coordination_spec.lua`, table-driven, one row per rule and every worked example in SPEC.

## Acceptance criteria
- [ ] `export PATH="$HOME/.luarocks/bin:$PATH"; busted && luacheck .` passes
- [ ] Conventional Commit(s), split by concern

## Notes / risks
Riskiest logic; keep it free of WoW API calls so it's easy to test.
