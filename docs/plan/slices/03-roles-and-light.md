# 03 - roles-and-light
Priority: MUST · Depends on: 01 · Parallel-safe: no · Est: ~40 min
Requirements: R4, R5

## Goal
In a raid, each member gets blessings for their role (from their class for now), and Light fills in where a blessing does nothing.

## Tasks
- Code: new `Roles.lua` (in `BuffBot.toc` before `ClassBuffList.lua`): `BuffBot.RoleLists`, `BuffBot.ClassDefaultRole`, `BuffBot.RoleOf(unit) -> role, source` (class default only for now, source `"class"`).
- Code: `BlessingFor` (`ClassBuffList.lua`) takes the list from `RoleLists[RoleOf(unit)]` in a raid, `BlessingPriority` otherwise; Light as the last fallback in raids when nothing on the list is free.
- Code: add Blessing of Light (19977) and Greater Blessing of Light (25890) to `spellIDTable`, `Blessings`, `GroupVersions`, `GroupBuffs`; and to `tests/mocks/spells.lua`. Keep Light off `SelfBlessings`.
- Tests: new `roles_spec.lua`: class defaults per class; a raid Warrior with another Paladin's Might gets Kings, and with Might and Kings taken gets Light; a party member never gets Light (existing `group_spec` passes unchanged).

## Acceptance criteria
- [x] `export PATH="$HOME/.luarocks/bin:$PATH"; busted && luacheck .` passes
- [x] Party behaviour is unchanged: every existing Paladin spec in `group_spec.lua` passes
- [x] Conventional Commit(s), split by concern

## Notes / risks
Light on yourself: only through the role list fallback, not the dropdown.
