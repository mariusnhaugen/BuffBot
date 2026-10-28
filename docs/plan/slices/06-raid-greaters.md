# 06 - raid-greaters
Priority: MUST · Depends on: 04, 05 · Parallel-safe: no · Est: ~40 min
Requirements: R8, R9, R10

## Goal
As the raid's only BuffBot Paladin, the button uses Greater Blessings per class and single casts for exceptions, biggest wins first.

## Tasks
- Code: in `MissingBuffs` (`BuffBot.lua`), in a raid and for a blessing, build a per-class plan instead of per-subgroup `AddGroupBuff`: per class, each member's pick (`BlessingFor`), the class blessing from the majority role (tie → class default role), exceptions; Greater vs singles by the SPEC rules (1 member, `CastableGroupVersion`, most out of range, the Q22 count rule with its tie rule). Entries carry `class` for Greaters.
- Code: order Greaters by members missing (desc), then a fixed class order; then all singles. Your own buffs stay first.
- Tests: new `greater_spec.lua`: 5 Priests → one Greater Wisdom; 1 Mage → single; a Feral Druid (manual melee) among Resto Druids → Greater Wisdom then Might single after all Greaters; one dead Warrior returning → single, not a Greater; the Q22 tie with an exception → singles; no reagent → singles; most out of range → singles. Change "never casts a Greater Blessing" in `group_spec.lua` to party-only.

## Acceptance criteria
- [ ] `export PATH="$HOME/.luarocks/bin:$PATH"; busted && luacheck .` passes
- [ ] `h:buffUp()` in a 10-member raid converges with Greaters before singles
- [ ] Conventional Commit(s), split by concern

## Notes / risks
The largest single-Paladin slice; split exceptions/Q22 into a follow-up if it runs long.
