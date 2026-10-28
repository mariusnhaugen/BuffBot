# 01 - settings
Priority: MUST · Depends on: 00 · Parallel-safe: yes · Est: ~20 min
Requirements: R1, R2

## Goal
Group buffing covers the whole raid without an extra setting, and "Buff your group" is the one switch.

## Tasks
- Code: `GroupUnits` (`BuffBot.lua`) always appends the other subgroups after your own; drop `RAID_BUFFING` from `GetDefaultConfig` and `RegisterSettings` (`Config.lua`, CRLF); clear `BuffBotConfig.RAID_BUFFING` on `ADDON_LOADED` (`EventFunctions.lua`, like `SUGGESTION_LIST`).
- Code: rename the `GROUP_BUFFING` label to "Buff your group"; tooltip "Your party, or the whole raid, starting with your own subgroup." plus the existing reagent sentence.
- Tests: update raid specs in `group_spec.lua`/`config_spec.lua` that set `RAID_BUFFING`; add: a saved `RAID_BUFFING` is cleared on load; a raid member in another subgroup gets buffed after your own subgroup; group buffing off = self-buffs only in a raid.
- Docs: CHANGELOG 2.5.0 "Removed: 'Buff the whole raid'. BuffBot now always covers the whole raid." and the rename under "Changed".

## Acceptance criteria
- [ ] No reference to `RAID_BUFFING` remains outside the load-time cleanup (`grep -rn RAID_BUFFING`)
- [ ] `export PATH="$HOME/.luarocks/bin:$PATH"; busted && luacheck .` passes
- [ ] Conventional Commit(s), split by concern

## Notes / risks
Applies to every class, not just Paladins.
