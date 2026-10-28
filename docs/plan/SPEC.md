# BuffBot 2.5 spec: raid blessing coordination

Source: TODO 29 and three `/grill-me` design sessions (Q1–Q31, 2026-10-26 to
2026-10-28). Generated 2026-10-28. This file is the record of the design;
`PROGRESS.md` tracks the build, one slice at a time with `/slice next`.

BuffBot Paladins in a raid agree over add-on messages on who owns which
blessing, give each raid member the blessings for their *role*, and use
Greater Blessings with per-member exceptions. As automatic as reasonable,
with as few settings as possible (TODO 18).

## Requirements

| ID | Pri | Requirement | Slice |
|---|---|---|---|
| R1 | MUST | `RAID_BUFFING` deleted (cleared on load); in a raid, group buffing covers the whole raid, own subgroup first | 01 |
| R2 | MUST | `GROUP_BUFFING` renamed "Buff your group", the single opt-out; off = self-buffs only, no `BB` messages | 01, 10 |
| R3 | MUST | Battleground or arena: no group buffing and no messages | 02 |
| R4 | MUST | Roles tank/melee/ranged/caster/healer, with role lists and class defaults; raids only, parties keep class lists | 03 |
| R5 | MUST | Light is the filler when a blessing does nothing for a member; it's on no role list | 03 |
| R6 | MUST | `/bb role <name> <role>` and `/bb role <name>`: manual roles saved account-wide, partial names | 04 |
| R7 | MUST | Your own role comes from your talents, overridable by the manual list | 04 |
| R8 | MUST | Greaters in raids: one per class by majority role; exceptions get singles; singles when the class has one member, the Greater can't be cast, or most of the class is out of range | 06 |
| R9 | MUST | A partly covered class compares cast counts; on a tie, Greater unless it wipes an exception | 06 |
| R10 | MUST | Cast order: own buffs, then Greaters (most missing first), then singles | 06 |
| R11 | MUST | Flat suggestion list (`Greater Blessing of Wisdom > Priests`, `Blessing of Might > Feralname`) | 07 |
| R12 | MUST | Protocol `BB:v1` on `RAID` under the `BuffBot` prefix; other versions are outsiders; `/bb debug` prints traffic | 08, 10 |
| R13 | MUST | Slot rules: table by Paladin count, name sort, sticky, collisions, reserves, Might/Wisdom split, shrink merges | 09 |
| R14 | MUST | Handshake: hello, answers, state, settle window; leaving or going offline frees a slot, dying doesn't | 10 |
| R15 | MUST | Slot to blessing per member, Light filler, outsider fallback; the self-blessing dropdown ignored while coordinating | 11 |
| R16 | MUST | Reload restores your slot; login and leaving the raid clear it | 12 |
| R17 | MUST | Multi-client tests show every client agrees on the slots | 13 |
| R18 | SHOULD | Detection: main-tank mark, group-finder role | 14 |
| R19 | SHOULD | Detection: talent auras, cached per GUID | 15 |
| R20 | SHOULD | Detection: Inspect queue for unknown hybrids | 16 |
| R21 | SHOULD | `/bb raid` status output | 17 |
| R22 | MUST | TESTING.md launch checks, CHANGELOG, version 2.5.0 | 00, 18 |

## Assumptions & open questions

- **No probes before coding (Q27).** Everything unprobed is mocked on the
  Classic API and the probed `PARTY` behaviour, and listed in `TESTING.md`
  "Test at launch": `RAID` add-on messages and their burst limit,
  `GetPartyAssignment("MAINTANK", unit)`, `GetRaidRosterInfo`, Inspect and
  `GetTalentTabInfo` on Forever's trees, talent-only auras, Greater Blessing
  rules, Light IDs.
- Light and Greater Light use the Classic IDs (19977, 25890) until checked.
- In a raid, assume everyone is level 60, but still check spells are learned
  (Kings at 20, Greater Blessings at 60).
- Forever facts from the user (not Classic knowledge): single and Greater
  Blessings both last 60 minutes; improved-blessing talents are gone;
  Sanctity Aura isn't a Ret talent; Sanctuary looks deleted; Salvation is its
  own spell; hybrid specs (Feral, Enhancement, Ret, Balance) are viable and
  common.
- **Add-on message API (from the API docs, 2026-10-28):**
  - Each prefix has 10 messages, refilling at 1 per second; past that, a
    send returns `AddonMessageThrottle` (3) and is dropped.
  - Read the result with `select(-1, C_ChatInfo.SendAddonMessage(...))`: a
    deprecation wrapper moves it to the last return value.
  - Results: 0 Success, 1 InvalidPrefix, 2 InvalidMessage, 3
    AddonMessageThrottle, 4 InvalidChatType, 5 NotInGroup, 8
    ChannelThrottle, 9 GeneralError, 11 AddOnMessageLockdown (new in
    12.0.0, likely in combat in instances), 12 TargetOffline.
  - Messages are at most 255 characters. `"RAID"` falls back to `"PARTY"`
    outside a raid.
- **Roster API (from the API docs):** `GetRaidRosterInfo(i)` returns name,
  rank, subgroup, level, class, fileName, zone, online, isDead, role, isML,
  combatRole. `GROUP_ROSTER_UPDATE` doesn't fire when a member goes offline;
  `UNIT_CONNECTION(unit)` does. `PLAYER_ENTERING_WORLD` passes
  `isInitialLogin, isReloadingUi`, and saved variables are loaded before it.
- **Talent API:** `GetTalentTabInfo` and the spec APIs
  (`GetSpecializationInfo`, `GetInspectSpecialization`, …) exist on the
  Classic clients; which return useful data on Forever is a launch check.
- One realm, so `GetUnitName(unit, true)` ("First Last") is the identity for
  names everywhere: message senders, the manual role list, name sort.

## Stack & run command

Lua add-on for WoW Forever (interface 16001). Tests: busted with the mocks in
`tests/`, plus luacheck:

```sh
export PATH="$HOME/.luarocks/bin:$PATH"; busted && luacheck .
```

In game: `./deploy.sh` copies the add-on into the AddOns folder.

## Domain model

### Roles (raids only)

| Role | Blessing list | Default for |
|---|---|---|
| tank | Kings > Might | main-tank marked |
| melee | Might > Kings | Warrior, Rogue |
| ranged | Kings > Wisdom > Might | Hunter |
| caster | Wisdom > Kings | Mage, Warlock |
| healer | Wisdom > Kings | Priest; Druid, Shaman, Paladin by default |

Feral, Enhancement and Ret are melee; Balance and Elemental are caster.
Light is on no list: it's the filler (below).

**Detection, first match wins:**
1. Manual list (`/bb role`), saved account-wide in `BuffBotConfig.ROLES`
   (`{ ["First Last"] = "melee" }`). Not shared with other Paladins.
2. Group markers: main-tank mark → tank; `combatRole` from
   `GetRaidRosterInfo` (or `UnitGroupRolesAssigned`) if Forever fills it in.
3. Talent auras seen on the member: Moonkin Form, or Moonkin Aura from that
   Druid → caster; Leader of the Pack with `sourceUnit` = that Druid →
   melee. Not Cat Form (travel form), not Sanctity Aura. IDs are Classic's
   (24858, 24907, 24932) until checked.
4. Inspect, for still-unknown hybrids (Druid, Shaman, Paladin; Warrior for
   Prot when nobody is main-tank marked).
5. Class default.

Layers 3 and 4 are cached in `roleByGUID[guid] = { role, source }` for the
session, dropped when the member leaves. Until a result arrives, the class
default applies. When a role changes, a blessing already up stays until due.
Respecs aren't handled (TODO 32); `/bb role` fixes mistakes.

**Your own role** comes from your own talents (`GetTalentTabInfo`, no Inspect
needed), overridden by the manual list.

### Slots: one blessing per Paladin for the whole raid

| BuffBot Paladins | Slots |
|---|---|
| 1 | No coordination: each member gets their role's first free choice |
| 2 | `K` Kings · `MW` Might or Wisdom per member, by role |
| 3 | `K` · `W` · `M` |
| 4 | `K` · `W` · `M` · `L` Light |
| 5+ | the rest hold `-` and are reserves |

**Light filler:** when a Paladin's slot blessing does nothing for a member,
that Paladin gives them Light. A member has at most one useless slot, so two
Paladins never both give Light. E.g. with 3 Paladins, the Wisdom Paladin gives
melee and tanks Light, and the Might Paladin gives casters and healers Light.

### State

- `peers["First Last"] = slot`: what each BuffBot Paladin last announced.
- `mySlot`: your own slot, announced on every change.
- `BuffBotCharConfig.SLOT`: your slot, saved for a reload.
- `settling`: true for ~3 s after a hello is sent or seen.

## Protocol contract

Prefix `"BuffBot"` (registered on load), channel `"RAID"`.

```
BB:v1:<slot>     state: the slot I hold        e.g. BB:v1:MW
BB?:v1:<slot>    hello: everyone answer with state   e.g. BB?:v1:-
```

`<slot>` is `K`, `W`, `M`, `MW`, `L` or `-`. A message with another version
makes its sender an outsider. Messages carry *facts* (who holds what); every
client derives *decisions* locally from the same rules. No negotiation.

**When to send:**
- Hello when the player starts taking part: joining a raid, logging in or
  reloading in one (the first roster check after load), or turning group
  buffing back on. Zoning doesn't restart the add-on, so it sends nothing.
- An answer (state) to every hello, after a random 0–2 s delay, unless the
  player already sent their state since the hello (a slot change does that).
  A Paladin whose own hello is still settling answers at its settle instead,
  once, even if its slot didn't change.
- State whenever your own slot changes.
- A send that doesn't return `0` (e.g. `AddOnMessageLockdown` in combat)
  is retried once on `PLAYER_REGEN_ENABLED`.
- No timers otherwise. A newcomer costs 1 hello + 1 answer per Paladin, well
  under the 10-message burst (excess is dropped, not queued).

**Settle window:** after a hello, wait ~3 s for answers, then compute. Seeing
another Paladin's hello also holds blessings for ~3 s.
Blessing casts are held while settling (self-buffs and auras aren't), so
nobody spends 60 minutes holding a blessing that belongs to another slot.

**Who sends nothing:** a Paladin with "Buff your group" off, anyone in a
battleground or arena, and every non-Paladin.

### Slot rules

- **Fresh assignment** (a raid forming, simultaneous hellos): name sort by
  `GetUnitName(unit, true)`, in slot order K, MW / K, W, M / L, then reserves.
- **Sticky:** a newcomer takes the first free slot.
- **Split (2 → 3):** the MW holder keeps W, the newcomer takes M.
- **Collision:** a hello or state claiming a slot someone already holds gives
  way; the existing holder keeps it. Only two simultaneous fresh claims are
  settled by name sort. The loser takes the first free slot or becomes a
  reserve, and re-announces.
- **Reserves:** a freed slot goes to the first reserve by name sort. Until
  then a reserve buffs as an outsider would (self-buffs plus the per-member
  fallback).
- **A Paladin leaving** (leaves the raid, or goes offline: `UNIT_CONNECTION`,
  since `GROUP_ROSTER_UPDATE` doesn't fire for it) frees their slot. Dying doesn't. Being elsewhere (in town, hearthed) doesn't.
- **Shrink (Q29):** a reserve fills the freed slot first, and nothing merges.
  Otherwise:
  - 4 → 3: L leaving moves nothing; any other slot is filled by the L holder.
  - 3 → 2: M leaves → W becomes MW; W leaves → M becomes MW; K leaves → the M
    holder takes K and the W holder becomes MW.
  - 2 → 1: the last Paladin drops coordination.
- **Opting out mid-raid (Q30):** not handled. A holder who turns group
  buffing off keeps the slot in others' view until they leave or go offline.
- **Handover:** the old owner's blessings stay until due; then the new owner
  casts. Nothing that's up is overwritten.

**How each client applies them:** `BuffBot.NextSlot(me, mySlot, peers,
event)` (`Coordination.lua`) is a pure function that returns the player's own
slot; each client only ever decides its own slot and announces it.
- `{ kind = "settle" }`: the player's own hello window ended. A slot a peer
  holds goes to the peer (the player gives way).
- `{ kind = "claim", name }`: a peer's hello or state changed `peers` while
  the player is settled. A slot both hold goes to the first by name.
- `{ kind = "peerLeft", name, slot }`: a peer left or went offline (already
  removed from `peers`); reserve, then close-up rules.
- In every case the MW holder reads as W from 3 Paladins on, a slot that
  doesn't exist for the count is dropped, and a Paladin without a slot fills
  the free slots by name sort (reserves only move on `peerLeft`, since no
  slot is free otherwise).
- Recording a hello: a peer's hello slot is recorded only if nobody else
  holds it, otherwise the peer is recorded as `-`. So a stale reload never
  frees or contests the holder's slot, and a real reload keeps its own.

**Worked examples:**
- A and B form a raid: both `BB?:v1:-`, settle, name sort → A `BB:v1:K`,
  B `BB:v1:MW`.
- C joins: `C: BB?:v1:-` → A `BB:v1:K`, B `BB:v1:MW` → B `BB:v1:W`,
  C `BB:v1:M`.
- From K/W/M, A (K) leaves: C `BB:v1:K`, B `BB:v1:MW`.
- Stale reload save: `A: BB?:v1:W` → `B: BB:v1:W` (B holds it, A gives way)
  → `A: BB:v1:M` (first free) or `A: BB:v1:-`.

### Reload

Save your slot in `BuffBotCharConfig.SLOT` when it changes. When the
player starts taking part, the hello carries a saved slot (`BB?:v1:W`).
Since the save is cleared on login (`PLAYER_ENTERING_WORLD` with
`isInitialLogin`) and on leaving the raid, a save that's still there means a
reload; `isReloadingUi` isn't needed. On login or relog, start at `-` (going offline
already freed the slot). Clear the save on login and on leaving the raid
(`GROUP_ROSTER_UPDATE` with `IsInRaid()` false). Loading screens don't
restart the add-on. The collision rule handles stale saves.

## Blessing selection

### Per member (`BlessingFor`)

- **Parties, solo:** unchanged from 2.4 (class lists, the dropdown on
  yourself).
- **Raid, the only BuffBot Paladin (or a reserve, or outside coordination):**
  the member's role list; the first free blessing (learned, not on them from
  another Paladin); then Light. Your own blessing follows the dropdown.
- **Raid, coordinating:** your slot's blessing (MW → Might or Wisdom by the
  member's role, whichever is higher on their list); Light when it does
  nothing for them, unless another Paladin holds Light's slot (then
  nothing). If your slot's blessing is already on them from someone else
  (an outsider), the next useful blessing nobody has given them, down their
  role list, skipping blessings another slot covers, then Light. The `PALADIN_BLESSING` dropdown is ignored:
  you're just another member.
- Never cast over another Paladin's blessing, even when it's fading (only
  your own buffs are refreshed early).

### Greater Blessings (raids)

- One Greater per class: the blessing most of the class's members get from
  you (each member's pick from their role list, after other Paladins'
  blessings). That's the majority role's blessing unless outsiders cover
  some members, and then it saves casts. A tie goes to the blessing the
  class's default role ranks higher.
- Your own Greater Blessing on a member doesn't "stand" the way a single
  does: it went on for the class, so the member's own pick decides, and an
  exception gets their single even with the Greater up.
- Members whose own pick differs are **exceptions** and get singles. A
  Greater wipes the same Paladin's singles on that class, so exceptions are
  recast after it.
- **Singles instead of the Greater** when the class has one member; the
  Greater isn't learned, or there's neither Symbol of Kings (21177) nor
  Reagent Economy; or most of the class is out of range.
- **Partly covered class (Q22):** Greater costs 1 + every exception of yours
  in that class it would wipe; singles cost 1 per member missing it. Pick
  fewer; on a tie, Greater, unless it wipes an exception. Drift
  self-corrects: the first member coming due triggers a Greater.

### Cast order (Q23)

1. Your own buffs as today: aura, Righteous Fury if on, your blessing on you.
2. All Greaters, the class with the most members missing your blessing
   first, ties in a fixed class order.
3. All singles: exceptions and stragglers.

Out-of-range members are skipped, not waited on.

## Screens

- **Button:** unchanged; it prompts the next cast. No slot label, no "you now
  cover X" chat line.
- **Suggestion list:** flat, no member counts:
  ```
  Greater Blessing of Wisdom > Priests
  Greater Blessing of Wisdom > Druids
  Blessing of Might > Feralname
  ```
- **Settings:** "Buff the whole raid" removed. "Buff your group" tooltip:
  "Your party, or the whole raid, starting with your own subgroup." The
  self-blessing dropdown's tooltip gains: "In a raid with other BuffBot
  Paladins, blessings follow the raid's assignment."
- **`/bb role <name> <role>`:** sets a role (partial name matched against the
  raid); `/bb role <name>` clears it. Prints what changed.
- **`/bb raid`:** BuffBot Paladins and their slots (reserves as "reserve"),
  "Not on BuffBot: …" for Paladins with no messages, and each role with its
  source: "Feralname – melee (manual)", "(aura)", "(inspect)", "N waiting".
- **`/bb debug`:** also prints every message sent and received.

## Inspect queue

`CanInspect` → `NotifyInspect` → `INSPECT_READY` (match the GUID) →
`GetInspectSpecialization(unit)` if it returns a spec on Forever, otherwise
`GetTalentTabInfo(tab, true)` (most points = spec) → `ClearInspectPlayer`.
About 28 yd, one at a time, ~1 per 1.5 s. Runs only when **all** hold:
- you're a Paladin in a raid;
- your slot depends on role (anything but K), or you're the raid's only
  BuffBot Paladin;
- out of combat;
- `InspectFrame` isn't shown;
- the member is a hybrid left unknown by the cheaper layers.

Out-of-range members are skipped and retried on the next pass: the queue
stops when nobody in range is left, and starts again on the next roster
change or at the end of combat. An inspect gets 5 s for its
`INSPECT_READY`; a member is tried at most 3 times per session. Answers to
other inspects (the player's own, other add-ons') are ignored. Spec IDs map
to roles by the standard IDs (e.g. Druid 102 Balance, 103 Feral, 104
Guardian, 105 Restoration). Results stay local.

## Settings

- `RAID_BUFFING` is deleted and cleared from saved settings on load.
  CHANGELOG: "Removed: 'Buff the whole raid'. BuffBot now always covers the
  whole raid."
- `GROUP_BUFFING` ("Buff your group", default on) is the single opt-out for
  every class: party in a party, whole raid in a raid, own subgroup first.
  Off: self-buffs only, and a Paladin sends no messages (counts as an
  outsider).
- Battlegrounds and arenas: group buffing off regardless (CHANGELOG
  "Changed").

## Outsiders

Paladins without BuffBot v1 never take a slot; conflicts with them are sorted
out in voice. The per-member fallback works around their blessings, decided
per member, so one outsider blessing doesn't block your Greater on the rest
of the class (covered members become exceptions).

## Out of scope

- Parties keep 2.4 behaviour (roles in parties: TODO 31).
- Salvation and Mass Salvation (TODO 30).
- Respecs (TODO 32).
- PvP: maybe later, tested on live.
- Combat log parsing (needs a probe; retail restricts it).
- Opting out mid-raid (Q30).
- Sharing Inspect results over messages (trust problems, small gain).
- A Greater/reagent flag in messages; splitting a slot by class across extra
  Paladins; a zone-based "away" rule; a settings textbox for roles.

## Test strategy (Q28)

- **Scripted peers:** one client; specs inject `CHAT_MSG_ADDON` from fake
  Paladins (`h:receive("Bob Smith", "BB:v1:K")`) and assert on what it sent
  (`h:sent()`). For collisions, reload, stale saves, odd messages.
- **Multi-client** (`tests/helpers/raid.lua`): N real sandboxes, one shared
  roster and clock, a bus delivering `RAID` messages to everyone including
  the sender on the next tick, 10 messages per client refilling at 1 per
  second (sends past that return `3` and are dropped), `math.random` stubbed per client. For "every client
  agrees" join, leave, split, shrink and reload sequences.
