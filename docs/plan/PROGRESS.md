# BuffBot 2.5 progress

Built on `release/2.5`, one slice at a time with `/slice next`. Design: `SPEC.md`.

- [x] 00 docs-groundwork (MUST, ~15m) — 11 launch checks in TESTING.md; your own role's talents folded into the Specs check
- [x] 01 settings (MUST, ~20m) — also updated README settings list
- [x] 02 pvp-self-only (MUST, ~15m) — `BuffBot.InPvP()` in HelperFunctions.lua; PLAYER_ENTERING_WORLD now also re-checks buffs, so zoning in or out updates the button
- [x] 03 roles-and-light (MUST, ~40m) — your own blessing in a raid keeps the dropdown + Paladin list, with Light last; CHANGELOG New entries added
- [x] 04 manual-and-own-role (MUST, ~30m) — role is the last word when it names a role, so full names with spaces work; talent points read from either the Classic Era or the later GetTalentTabInfo layout; README + CHANGELOG
- [x] 05 greater-harness (MUST, ~20m) — Greaters land class-wide in parties too (matches the game); new State:classmatesOf; greater_spec.lua started
- [x] 06 raid-greaters (MUST, ~40m) — SPEC changed: class blessing = majority of members' picks; own Greater no longer 'stands' in BlessingFor; your own blessing waits until after a Greater on your class that would replace it; harness now replaces the player's other blessing on a unit
- [ ] 07 flat-suggestions (MUST, ~15m)
- [ ] 08 message-mocks (MUST, ~30m)
- [ ] 09 slot-rules (MUST, ~40m)
- [ ] 10 protocol-wiring (MUST, ~40m)
- [ ] 11 slot-blessings (MUST, ~30m)
- [ ] 12 reload-restore (MUST, ~20m)
- [ ] 13 multi-client (MUST, ~40m)
- [ ] 14 detect-markers (SHOULD, ~20m)
- [ ] 15 detect-auras (SHOULD, ~25m)
- [ ] 16 inspect-queue (SHOULD, ~40m)
- [ ] 17 bb-raid (SHOULD, ~25m)
- [ ] 18 release-prep (MUST, ~20m)

MUST total: ~415 min (6.9 h). SHOULD (14–17): ~110 min.

## Cut lines

- **After 07:** a "solo raid Paladin" release: whole-raid buffing, roles, Light, Greater Blessings. Run 18 to ship.
- **After 13:** coordination with class-default and manual roles. Run 18 to ship.
- 14–17 (detection layers and `/bb raid`) are SHOULD: drop these first.

Each slice works on its own, so if Forever launches early the branch can ship from wherever it got to.
