# 10 - protocol-wiring
Priority: MUST · Depends on: 09 · Parallel-safe: no · Est: ~40 min
Requirements: R2, R12, R14

## Goal
BuffBot Paladins in a raid announce themselves and settle on slots.

## Tasks
- Code: hello on joining a raid (`GROUP_ROSTER_UPDATE` into a raid) and on `PLAYER_ENTERING_WORLD`; answer a hello after `C_Timer.After(math.random() * 2)`; send state when your slot changes; ~3 s settle, during which blessing entries are left out of `MissingBuffs`; a roster pass drops peers who left or went offline (feeding `peerLeft`); senders with another version are outsiders; no messages for non-Paladins, with group buffing off, or in PvP; `/bb debug` prints each message.
- Tests: scripted peers in `coordination_spec.lua`: join → hello; a hello is answered once after the delay; two peers → settle → state; a peer going offline frees their slot; `BB:v2:K` is ignored; nothing is sent with group buffing off; blessings wait during the settle window but self-buffs don't.

## Acceptance criteria
- [ ] `export PATH="$HOME/.luarocks/bin:$PATH"; busted && luacheck .` passes
- [ ] No send happens more than once per event (the burst budget)
- [ ] Conventional Commit(s), split by concern

## Notes / risks
Senders are matched against `GetUnitName(unit, true)`.
