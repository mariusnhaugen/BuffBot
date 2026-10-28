# 16 - inspect-queue
Priority: SHOULD · Depends on: 15, 11 · Parallel-safe: no · Est: ~40 min
Requirements: R20

## Goal
Unknown hybrids are inspected in the background and get their spec's role.

## Tasks
- Code: queue in `Roles.lua`: `CanInspect` → `NotifyInspect` → `INSPECT_READY` (match GUID) → `GetInspectSpecialization(unit)` when it returns a spec ID, else `GetTalentTabInfo(tab, true)` → `ClearInspectPlayer`; ~1 per 1.5 s; only under the SPEC conditions; out-of-range skipped and retried; cache by GUID (source `"inspect"`); dropped on leave.
- Tests: mocks for the Inspect API and `InspectFrame`; one at a time; not in combat; not while `InspectFrame` is shown; not for a K holder with other BuffBot Paladins; Warriors only when nobody is MT-marked; a result changes the role.

## Acceptance criteria
- [ ] `export PATH="$HOME/.luarocks/bin:$PATH"; busted && luacheck .` passes
- [ ] Conventional Commit(s), split by concern

## Notes / risks
May clash with other add-ons' Inspect use; unprobed on Forever.
