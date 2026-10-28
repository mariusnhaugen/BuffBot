# 17 - bb-raid
Priority: SHOULD · Depends on: 16 · Parallel-safe: yes · Est: ~25 min
Requirements: R21

## Goal
`/bb raid` shows who covers what and why each member has their role.

## Tasks
- Code: `/bb raid` in `Config.lua`: BuffBot Paladins and slots ("reserve" for `-`), "Not on BuffBot: …" for roster Paladins with no messages, each member's role with its source, and "N waiting" for queued inspects.
- Tests: output for a raid with 3 BuffBot Paladins, an outsider, a manual role and a waiting inspect.

## Acceptance criteria
- [x] `export PATH="$HOME/.luarocks/bin:$PATH"; busted && luacheck .` passes
- [x] Conventional Commit(s), split by concern

## Notes / risks
None.
