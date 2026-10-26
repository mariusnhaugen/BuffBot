# BuffBot TODO

Open work for the Forever branch. Tick items off as they land, and note the
commit.

## Feature ideas

- 29. Part 2 of blessing sharing: Paladins agree on who gives which
  blessing over add-on messages, so two Paladins never cast the same one at
  once, plus Greater Blessings (Symbol of Kings or Reagent Economy). Linked
  to 21. Part 1 is done: each Paladin gives a member the first blessing on
  their class list that no other Paladin has given them. Messages go to
  PARTY or RAID; the sender's name matches `GetUnitName(unit, true)`, and
  about 10 go out at once (PROBE_RESULTS.md).

- 18. Settings page cleanup. Show only the current class's settings. General UX. Make paladin prio?
- 26. Known issue: the first Rockbiter cast once needed a second press
  before the button moved on. Not reproduced since. A probe for
  `UNIT_INVENTORY_CHANGED` printed nothing, so the event may not always
  fire, or `C_Item.GetWeaponEnchantInfo` may lag behind it.
- 21. More Paladin buffs: Light, Sanctuary. Kings is done: on yourself
  through the blessing dropdown, and on Hunters and Paladins in the party.
- 30. Salvation. On Forever it is its own spell, not a blessing, so it
  stacks with blessings; Mass Salvation is the group version. Wowhead lists
  Salvation as 1038 (the old Blessing of Salvation ID; a third-party site
  calls it "renamed"), so Mass Salvation is probably the old Greater
  Blessing's ID too. Check both IDs, durations and the Mass version's
  reagent at launch. Never give it to tanks: main-tank mark
  (`GetPartyAssignment("MAINTANK", unit)`), group finder role
  (`UnitGroupRolesAssigned`) or a tank aura (Defensive Stance, Bear Form,
  Righteous Fury). It's outside the blessing lists, so part 2 (29) only
  needs to decide which Paladin casts it.
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
