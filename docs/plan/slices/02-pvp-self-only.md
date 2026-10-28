# 02 - pvp-self-only
Priority: MUST · Depends on: 01 · Parallel-safe: yes · Est: ~15 min
Requirements: R3

## Goal
In a battleground or arena, BuffBot buffs only you.

## Tasks
- Code: move the pvp/arena check from `Tracking.lua:64` into a shared `BuffBot.InPvP()` (e.g. `HelperFunctions.lua`, CRLF) and use it in Tracking and in `GroupUnits`, which returns `{ { "player" } }` there.
- Tests: in a raid with `state.instanceType = "pvp"` (and `"arena"`), only self-buffs; tracking specs still pass.
- Docs: CHANGELOG "Changed: in battlegrounds and arenas, BuffBot only buffs you."

## Acceptance criteria
- [x] `export PATH="$HOME/.luarocks/bin:$PATH"; busted && luacheck .` passes
- [x] Conventional Commit(s), split by concern

## Notes / risks
Slice 10 also checks `InPvP()` before sending messages.
