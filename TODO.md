# BuffBot TODO

Open work for the Forever branch. Tick items off as they land, and note the
commit.

## Feature ideas

- 18. Settings page cleanup. Show only the current class's settings. General UX. Make paladin prio?
- 26. Known issue: the first Rockbiter cast once needed a second press
  before the button moved on. Not reproduced since. A probe for
  `UNIT_INVENTORY_CHANGED` printed nothing, so the event may not always
  fire, or `C_Item.GetWeaponEnchantInfo` may lag behind it.
- 30. Salvation, after 2.5. On Forever it is its own spell, not a
  blessing, so it stacks with blessings. Wowhead lists Salvation as 1038
  (the old Blessing of Salvation ID; a third-party site calls it
  "renamed"), so Mass Salvation is probably the old Greater Blessing's ID
  too. Mass Salvation's tooltip: 16% of base mana, 40 yd, instant; 30% less
  threat for 1 hour on every raid or party member of the target's class.
  No reagent listed. Check the IDs and the single version's duration at
  launch.
  - Never on the tank role (part 2, 29): main-tank mark, Inspect, or the
    manual list.
  - Share the casts out between BuffBot Paladins instead of giving it to
    one slot, e.g. split the classes between them.
- 31. Roles in parties. Part 2 (29) gives raid members a role (tank,
  melee, ranged, caster, healer) that picks their blessings; parties keep
  the class lists for now. Inspect doesn't help while leveling: talents
  rarely match the role a character fills in a dungeon. Signals that would:
  the manual list, the group finder role (`TANK`, `HEALER`), and tanking
  auras (Righteous Fury, Defensive Stance).
  - Group arithmetic: in a full 5-person party, a role only one member can
    fill goes to them (3 Mages, a Priest and a Druid: the Druid tanks).
    Keep the tank and healer classes in a table, since Forever may change
    them.
- 32. Stale roles after a respec, after 2.5. Part 2 (29) caches Inspect
  results per GUID for the session, so a Resto Druid who goes Feral
  mid-raid keeps getting Wisdom until the session ends; for now the manual
  list (`/bb role`) fixes it. Ideas:
  - A fresher, cheaper signal (talent aura, main-tank mark) that disagrees
    with the cached result wins and drops the cache entry.
  - Re-inspect when a raid member casts a spec-change or talent-reset
    spell (`UNIT_SPELLCAST_SUCCEEDED`), if Forever has one and add-ons can
    see it. Needs a probe.
  - Expire cached results after about 30 minutes.
- 33. Hybrids with BuffBot announce their own role. A Druid, Shaman,
  Paladin or Warrior running BuffBot already knows its role from its own
  talents (`GetTalentTabInfo`, plus the manual list), so it can tell the
  raid over add-on messages and the Paladins skip detection layers 3–4
  (talent auras, Inspect) for that member. Also fixes TODO 32 for them:
  re-announce after a respec.
  - The manual list (layer 1) still wins over an announced role.
  - Needs a message the `BB:v1` rules don't treat as an outsider's, or a
    protocol bump; non-Paladins would send it too.
- 34. A window for checking the raid's roles and fixing wrong ones.
  `/bb raid` prints roles and their sources to chat, but a long raid is
  hard to read there and a fix means typing `/bb role <name> <role>` per
  member. A window could list members by group or role, with each one's
  role, source (manual, mark, aura, Inspect, class default) and blessing,
  and a dropdown or click to set the role (saved to the manual list) or
  clear it. Maybe also re-inspect a member or drop their cached result
  (TODO 32).
- 35. Bring back the usage text on the settings page. The Settings API
  rewrite (`cfb530f`) dropped the old canvas page's lines: set a keybind
  in the game's Key Bindings > AddOns for a spammable button, Alt+drag to
  move the button, and `/bb`, `/buffbot` to open the page. Now they only
  appear in the Hide Icon and Reset Button Position tooltips. The
  vertical-layout category may need a section header or a custom
  initializer for plain text.
  - The keybind now has its own row at the top of the page
    (`CreateKeybindingEntryInitializer`), written without the game to test
    it on; check it at launch (TESTING.md, Test at launch). If it works, the
    text only needs the Alt+drag and slash command lines.
- 36. Share out other classes' raid buffs, as the Paladins' blessings are
  (29). Two Mages both offer Arcane Intellect to the whole raid; they could
  split it by subgroup instead (Mage A groups 1–4, B 5–8), and the same for
  Priests' Fortitude and Druids' Mark of the Wild. Two ways:
  - Over add-on messages, like the `BB:v1` slots: each caster announces
    the groups they cover. Handles casters without BuffBot, but non-Paladin
    messages need a protocol change (as in 33).
  - Deterministic, no messages: every BuffBot caster of the class sorts
    the raid's casters by name and takes its share of the groups. Simpler,
    but it can't tell who runs BuffBot, so groups assigned to a caster
    without it go unbuffed unless they're covered after a timeout.
  - Group versions (Arcane Brilliance etc.) cover one subgroup per cast,
    so splitting by subgroup fits them.
- 25. Size sliders for the icon and the text. The icon scales the 48px
  button (`SetSize`, out of combat only), and the text changes the font
  size of the suggestion list. Both use the game's own slider, with no
  library.

## Decided against

- **Timer-based refresh for expiring buffs.** `UNIT_AURA` fires often
  enough, and it fires when the buff drops, so the player is never left
  without it.
- **Limiting `UNIT_AURA` to the player.** Group coverage needs it wide, and
  the current cost is one string comparison per event.
- **Debouncing `GROUP_ROSTER_UPDATE` (14).** A rebuild only checks the
  player's own short buff list, so dozens of them while a raid fills cost
  nothing noticeable. The group coverage re-scan is scheduled with
  `C_Timer.After`, which covers it once rebuilds scan every member.
- **Button tooltip and cooldown swipe (19).** More distracting than
  useful. The icon dims along with the blue tint when out of mana or rage
  instead.

## Done

- [x] 29, part 2. Raid coordination for 2.5: roles, Greater Blessings with exceptions, slots shared out over add-on messages, `/bb role` and `/bb raid` (`d57f9d6`, `9999d4a`, `267d427`, `de356f9`, `4ea5463`; design in `docs/plan/SPEC.md`)
- [x] 21. Blessing of Light as the raid filler (`2a815e1`). Sanctuary is a launch check in TESTING.md
- [x] 29, part 1. Blessings shared out between Paladins by class lists, and only your own buffs refreshed early (`5b6d413`, `472a85e`)
- [x] Paladin blessings on the party by class, Kings, and a self-blessing dropdown (`7e411d7`)
- [x] Group buffing: party, own raid subgroup and optional whole raid, with group versions and the class skip list (`7fc9031`)
- [x] Turn tracking back on automatically after death and login (`5e871be`)
- [x] Fill in settings missing from an older saved config (`4ba4a0b`)
- [x] Re-check buffs on a full aura update outside a raid (`aa27924`)
- [x] Group range checks added to the probe table (`ffaeffe`)
- [x] Remove unused `groupHasChanged` flag (`234fb0b`)
- [x] Skip single-target buffs covered by their group version (`2665b83`)
- [x] Reset Button Position does nothing in combat (`23f2cb2`)
- [x] `/bb buffs` prints the list instead of using `DevTools_Dump` (`7a0a88f`)
- [x] Only the player's own Paladin aura counts (`7bc2b80`)
- [x] Save the button position without the anchor frame (`54af139`)
- [x] Check every spell's availability the same way, without `RanklessSpells` (`39eeb24`)
- [x] Load message reads the version from the TOC; the TOC title keeps its own copy for the add-on menu (`b94f3e8`)
- [x] Probe results filled in (`a65e3f7`)
- [x] Copy-paste slips: Strict Armor debug message (`6977911`) and the global `t` texture (`c1139e3`)
- [x] Chain Bloodrage and Battle Shout in one macro, and remove the cast handler (`3d780ad`)
- [x] Show Battle Shout without rage, tinted blue and kept in sync (`d3804e0`)
- [x] Hide the button when dead, a ghost or on a flight path (`a043b8c`)
- [x] Button stayed up on a flight path: re-check after the taxi state changes (`18aeb1d`)
- [x] Shaman imbue setting is a dropdown (`8adf27a`)
- [x] 20. Rogue poisons, per hand (`d05f0ed`). The off-hand slot and charges still need a Rogue in game (see TESTING.md)
- [x] 28. Righteous Fury for Paladin tanks, opt-in (`fee1105`). Spell ID 25780 still to check in game
- [x] Turn on luacheck's unused-variable warnings (`57415f3`)
- [x] Remove dead code, including the `PLAYER_LOGOUT` handler (`57415f3`, `b056b5f`)
- [x] Hide Icon, and Hide Text in place of Show Suggestion List (`3ec0e15`)
- [x] Suggestion list follows the button's skip rules (`8ba46a6`)
- [x] Use the client's spell names, looked up by ID (`f279f20`)
- [x] Shaman weapon imbues, with a setting to pick the imbue (`8254999`)
