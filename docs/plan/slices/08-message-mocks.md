# 08 - message-mocks
Priority: MUST · Depends on: 00 · Parallel-safe: yes · Est: ~30 min
Requirements: R12

## Goal
Specs can send and receive add-on messages.

## Tasks
- Tests: `C_ChatInfo.RegisterAddonMessagePrefix` and `SendAddonMessage` mocks (`tests/mocks/api_forever.lua`): record `{ prefix, msg, channel }`; 10 per prefix refilling at 1 per second on the mock clock, past that return `3` and drop; return the result last, as the deprecation wrapper does (`nil, result`), so code must use `select(-1, ...)`; a settable `state.sendResult` to simulate `11` (lockdown); `h:receive(sender, msg)` fires `CHAT_MSG_ADDON` with prefix `BuffBot` and channel `RAID`; `h:sent()` returns sent messages; `math.random` stub on the env, settable per spec.
- Code: register the `BuffBot` prefix on `ADDON_LOADED`; a `CHAT_MSG_ADDON` handler stub that ignores other prefixes.

## Acceptance criteria
- [ ] `export PATH="$HOME/.luarocks/bin:$PATH"; busted && luacheck .` passes
- [ ] A spec asserts the prefix is registered on load
- [ ] Conventional Commit(s), split by concern

## Notes / risks
No protocol logic yet.
