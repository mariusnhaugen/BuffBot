# 00 - docs-groundwork
Priority: MUST · Depends on: - · Parallel-safe: yes · Est: ~15 min
Requirements: R22

## Goal
The repo lists every 2.5 check that has to wait for Forever launch, so nothing unprobed is forgotten.

## Tasks
- Docs: add to `TESTING.md` "Test at launch": `RAID` add-on messages reach everyone incl. the sender, and the burst limit is 10 like PARTY; `GetPartyAssignment("MAINTANK", unit)` after marking; `GetRaidRosterInfo` subgroup and class; Inspect flow and `GetTalentTabInfo(tab, true)` on Forever's trees; your own talents for your own role; which auras are talent-only (Moonkin, Leader of the Pack); Greater rules (class-wide, 40 yd, wipes your single); Light and Greater Light IDs (19977, 25890 assumed); two Paladins' blessings stacking; which channel reaches a battleground raid (for a later PvP release).

## Acceptance criteria
- [ ] Every item above is in `TESTING.md` "Test at launch"
- [ ] `git diff --stat` touches only `TESTING.md`
- [ ] Conventional Commit(s), split by concern

## Notes / risks
Docs only; commit as `docs:`.
