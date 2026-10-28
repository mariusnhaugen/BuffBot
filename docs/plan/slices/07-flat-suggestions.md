# 07 - flat-suggestions
Priority: MUST · Depends on: 06 · Parallel-safe: yes · Est: ~15 min
Requirements: R11

## Goal
The suggestion list reads `Greater Wisdom > Priests` for a Greater and `Might > Name` for a single.

## Tasks
- Code: `UpdateSuggestionList` (`Interface.lua`): a Greater entry shows its display name and the class plural (English table: Priests, Druids, …; other locales: the localized class name); singles unchanged.
- Tests: suggestions in a raid show the flat list; `locale_spec` still passes.

## Acceptance criteria
- [x] `export PATH="$HOME/.luarocks/bin:$PATH"; busted && luacheck .` passes
- [x] Conventional Commit(s), split by concern

## Notes / risks
Stop here for a "solo raid Paladin" release (cut line 1).
