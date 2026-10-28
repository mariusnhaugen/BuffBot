# 04 - manual-and-own-role
Priority: MUST · Depends on: 03 · Parallel-safe: no · Est: ~30 min
Requirements: R6, R7

## Goal
A raid leader can fix anyone's role with `/bb role`, and your own role follows your talents.

## Tasks
- Code: `/bb role <name> <role>` and `/bb role <name>` in `SlashCmdList.BUFFBOTSETTINGS` (`Config.lua`): partial, case-insensitive match against raid members' `GetUnitName(unit, true)`; ambiguous or no match prints the candidates; saves in `BuffBotConfig.ROLES` (default `{}`); prints the change.
- Code: `RoleOf` checks the manual list first (source `"manual"`); for the player, talents next: `GetTalentTabInfo(tab)` with most points, mapped per class to a role in `Roles.lua` (Druid: Balance caster / Feral melee / Resto healer; Shaman: Ele caster / Enh melee / Resto healer; Paladin: Holy healer / Prot tank / Ret melee; Warrior Prot tank), source `"talents"`.
- Tests: mocks for `GetUnitName(unit, true)` returning member names (player `"Tester"`) and `GetTalentTabInfo`; specs for set, clear, partial match, ambiguous match, saved across reload, own role from talents, manual overriding talents.

## Acceptance criteria
- [x] `export PATH="$HOME/.luarocks/bin:$PATH"; busted && luacheck .` passes
- [x] `/bb role` with no arguments prints usage
- [x] Conventional Commit(s), split by concern

## Notes / risks
Manual roles are keyed by full name, so they survive the member leaving and rejoining.
