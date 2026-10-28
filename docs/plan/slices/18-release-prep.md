# 18 - release-prep
Priority: MUST · Depends on: 13 · Parallel-safe: no · Est: ~20 min
Requirements: R22

## Goal
2.5.0 is ready to tag.

## Tasks
- Docs: CHANGELOG 2.5.0 pass (New: raid coordination, roles, Greater Blessings, Light, `/bb role`, `/bb raid`; Changed; Removed); TESTING.md in-game checks for 2.5.
- Code: `BuffBot.toc` `## Version` and `## Title` to 2.5.0 (`chore: bump version to 2.5.0`).
- Docs: tick TODO 29 and 21 off in a separate `docs:` commit with the hash.

## Acceptance criteria
- [x] `export PATH="$HOME/.luarocks/bin:$PATH"; busted && luacheck .` passes
- [ ] Push, ff-merge into `main`, and `git tag v2.5.0` only when the user asks (waiting on the user)
- [x] Conventional Commit(s), split by concern

## Notes / risks
Slices 14–17 can ship later if this runs before they're done.
