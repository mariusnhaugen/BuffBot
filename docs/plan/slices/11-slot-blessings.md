# 11 - slot-blessings
Priority: MUST · Depends on: 06, 10 · Parallel-safe: no · Est: ~30 min
Requirements: R15

## Goal
With 2+ BuffBot Paladins, each one casts their slot's blessing raid-wide, with Light where it does nothing.

## Tasks
- Code: `BlessingFor` while coordinating: slot blessing (MW → Might or Wisdom by role), Light when useless, outsider fallback down the role list then Light; the dropdown ignored; the per-class plan in slice 06 uses it unchanged. Reserves and the single BuffBot Paladin keep the slice 06 behaviour.
- Code: the `PALADIN_BLESSING` tooltip gains "In a raid with other BuffBot Paladins, blessings follow the raid's assignment."
- Tests: K holder gives Greater Kings everywhere; MW holder gives Greater Might to Warriors and Greater Wisdom to Priests; W holder (3 Paladins) gives Light to Warriors; an outsider's Wisdom on one Priest makes that Priest an exception; the dropdown is ignored for yourself.

## Acceptance criteria
- [ ] `export PATH="$HOME/.luarocks/bin:$PATH"; busted && luacheck .` passes
- [ ] Conventional Commit(s), split by concern

## Notes / risks
Handover: blessings already up stay until due (existing `BlessingFor` rule).
