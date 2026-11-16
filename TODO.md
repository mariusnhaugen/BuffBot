# BuffBot TODO

Open work for the Forever branch. Tick items off as they land, and note the
commit.

## Bugs

- 46. Taint blamed on BuffBot (BugSack reports from one player,
  2026-11-13). All four are Blizzard code running tainted and then hitting
  a secret value or a protected call:
  - `CompactUnitFrame.lua:698` compares the secret `oldR` in
    `CompactUnitFrame_UpdateHealthColor`, from `CompactPartyFrame`
    `RefreshMembers` (27x).
  - `ActionButton.lua:891` `SetCooldown` gets secret values, from
    `ActionBarController_UpdateAll` (471x).
  - `Blizzard_GamepadActionBars/ActionBarButton.lua:965` boolean test on a
    secret, from `UpdateFlyoutActionIcon` / `ClassSpellFlyout` (127x).
  - `ADDON_ACTION_FORBIDDEN` on `ClearTarget()`, from `EnterEditMode`
    `RefreshTargetAndFocus` (1x).
  None of the stacks has a BuffBot frame in it, so the code that spread
  the taint isn't known. BuffBot sets no globals beyond the slash commands,
  the binding name and its saved variables, and hooks nothing; the local
  `Logs/taint.log` (2026-11-05) only shows reads of those globals inside
  `securecallfunction`, which are harmless. The player is a Warrior who
  briefly joined a party around the time. So tracking casts (no Warrior
  trackers) and Inspect (Paladins in a raid only) are ruled out. What a
  Warrior in a party runs: the roster and party `UNIT_AURA` re-checks, the
  secure button's macro updates (Battle Shout, Bloodrage), and hiding the
  button on `PLAYER_REGEN_DISABLED`. Then the player found the trigger: the
  errors start after turning on a 4th action bar (in Settings or Edit
  Mode). That fits every stack: action bars, the gamepad bars, Edit Mode
  and the party frames all refresh after that change. So Blizzard's
  settings or Edit Mode code is likely running tainted when it applies the
  change. He also said "It's Ellesmere": EllesmereUI, a full UI
  replacement that runs on Forever. Its source (github.com/EllesmereGaming/EllesmereUI,
  read 2026-11-13) points at it:
  - It replaces the action bars with its own buttons, hides
    `ActionBarParent`, and turns on `SHOW_MULTI_ACTIONBAR_1`–`4` with
    `C_CVar.SetCVar` from add-on code (`EUI_ActionBars_Secure.lua`,
    `EUI_ActionBars_Setup.lua`). A CVar set from add-on code runs
    Blizzard's CVar callbacks tainted, which would explain all four stacks.
    BuffBot sets no CVars.
  - Why BuffBot gets the blame is unknown. WoW names the add-on that
    owns the last tainted value read, so it can be the wrong one.
  - Leaning: not a BuffBot bug. Confirm by turning on bar 4 with EllesmereUI
    and BuffBot disabled; if the errors still come, blamed on EllesmereUI
    or nothing, report it to EllesmereUI.
  Other EllesmereUI overlaps (no bug seen, worth a look):
  - Its AuraBuff Reminders module ("raid buff, auras, consumables and
    talent reminders") repeats what BuffBot does. Two reminders for the
    same buff is noise; README could say to turn one off.
  - Its own secure buttons register only `AnyUp` with
    `useOnKeyDown = false`, citing double casts when a button registers
    both phases under `ActionButtonUseKeyDown`. BuffBot's button
    registers `AnyUp` and `AnyDown` (`Interface.lua`). Check that a mouse
    click and a keybind each cast once, with the CVar on and off.
  Suspects on BuffBot's side, if the test above clears EllesmereUI:
  - The keybinding row on the settings page (`CreateKeybindingEntryInitializer`
    in `Config.lua`), a Blizzard initializer built from add-on code. Now
    the lead suspect: it lives in the same Settings panel as the action
    bar toggles. Test by building without it.
  - BuffBot's other settings-page parts: the custom
    `BuffBotSettingsTextTemplate` row and the Reset Button Position button.
  - Repro: only BuffBot, BugGrabber and BugSack; `/console taintLog 1`;
    `/reload`; turn on Action Bar 4; check BugSack and `Logs/taint.log`.
  - Next step: a taint log from a player who gets the errors
    (`/console taintLog 1`, `/reload`, play until it happens, then send
    `Logs/taint.log`), or reproduce with only BuffBot and BugSack on.

- 47. Hunter in a battleground gets Trueshot Aura and Aspect of the Hawk
  offered while both are up (player report, 2026-11-15). Not the PvP guard:
  `BuffBot.InPvP()` already limits BGs to self-buffs. Likely aura lookups
  return nothing there (PvPMatch restriction), and `BuffBot.AurasUnreadable`
  (`BuffBot.lua:31`) only checks combat and the encounter flag, so every
  buff reads as missing. Probe: "Auras in battlegrounds" in TESTING.md (the
  player has stopped doing BGs for now). If confirmed, also return true from
  `AurasUnreadable` when `C_Secrets.ShouldAurasBeSecret()` is true, which
  keeps the button quiet in BGs and closes the Map-restriction gap from the
  Blackfathom Deeps probe. Add a spec with auras secret in a BG.
  - Done ahead of the probe: `AurasUnreadable` also checks
    `ShouldAurasBeSecret()`, with specs in `combat_spec.lua` and a
    `/bb status` reason. Whether the flag alone covers combat and
    encounters too: "Does `ShouldAurasBeSecret` cover every case?" in
    TESTING.md.

## Feature ideas

- 18. Settings page cleanup. Show only the current class's settings. General UX. Make paladin prio?
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
- 40. Role detection for Paladins whose talent points don't match their
  job. `Roles.lua` `TalentRole` picks the tree with the most points, so a
  36/0/15 damage Paladin reads as healer, and a 21/30/0 healer as tank.
  Forever reshuffled the Holy, Protection and Retribution talents, so point
  layouts are even less reliable. Only missing a Paladin who wants Might
  really costs anything: healer and caster share Wisdom > Kings.
  - Infusion of Light lookup: `C_SpecializationInfo.GetTalentInfo({
    specializationIndex, talentIndex, isInspect })` returns `rank` and
    `spellID`; deep Holy without Infusion of Light means damage. Unknown:
    whether it survived the reshuffle, its ID, and whether every Holy
    healer takes it.
  - Weapon check after Inspect: a two-hander in `GetInventoryItemLink(unit,
    16)`, or an empty slot 17, means melee. Unknown: whether Forever returns
    item links after Inspect.
  - An own-role dropdown on the settings page ("My role: Auto / Tank /
    Healer / Melee / Caster"), announced to the raid with 33: the exact
    answer for BuffBot users.
  - Rejected: counting casts in the combat log (too late, too costly).
  - Leaning: the talent and weapon checks as a guess ahead of point count,
    the dropdown as the exact answer.
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
- 37. Paladins can disagree on a member's role. Each BuffBot Paladin works
  out roles on its own: `/bb role` is saved per player, Inspect results
  land at different times, and Kings' slot doesn't inspect at all. With
  three Paladins, Wisdom's and Might's holders each decide who their
  blessing does nothing for, so if they disagree on a hybrid, both may skip
  them and the member misses Might or Wisdom; a manual role set by one Paladin never
  clears up. Most of the fix is sharing roles: 33 (hybrids announce their
  own), and sending manual roles to the other Paladins. Short of that, a
  Paladin could give its slot's blessing to a hybrid whatever role it
  worked out.
- 43. Untangle Shaman weapon imbues from consumables. Mana oils stack with
  imbues in Forever, but `HasWeaponEnchant` (`BuffBot.lua`) counts any
  temporary enchant as the imbue, so an oil on the weapon stops the imbue
  being offered. The imbue check should only look for an imbue
  (`enchantType` 3), and an imbue running low shouldn't depend on the oil.
- 44. Oil reminders (distant future). Remind players to apply a mana or
  wizard oil, building on 43, along the lines of the eat reminder (42).
- 45. Don't suggest weapon buffs while a fishing pole is equipped. Shaman
  imbues for sure; Rogue poisons too, if that also applies. `SkipReason`
  (`BuffBot.lua`) only checks that a weapon is in the hand.

## Decided against

- **Salvation (30).** Forever removed Salvation and Mass Salvation
  (development notes, 2026-11-03), so there's nothing to share out.
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

- [x] 41. Skip a buff under a stronger scroll (2.6.3), since the cast fails with "A more powerful spell is active". Arcane Intellect (2, 7, 15, 22, 31) and Power Word: Fortitude (4, 10, 26, 42, 56, 70) against scrolls of 4, 8, 12, 16, from Wowhead's Forever database. Divine Spirit rank 1 (17) beats the best Spirit scroll (15), so it's left out. Ranks that beat every scroll never look at auras. Not covered, until someone reports it: a high-rank caster's buff dropping to a lower rank on a low-level target
- [x] 42. Remind players to eat while leveling (2.6.2), since Forever's cooked food gives 5% more XP from kills. A reminder only, off by default: no food list or bag check, and any Well Fed counts. Offering the food on the button is a possible next step
- [x] 35. Usage text on the settings page (2.6.1): one small line at the top on opening the page and Alt+drag, from a plain label template (`SettingsText.xml`); `/bb help` and unknown commands list the commands. The 2.6 Commands section with a button per command was clunky and is gone
- [x] 38. A role whose blessing the class can't use falls through to the next on the role's list (a Mage set to `melee` gets Kings, not nothing) (2.5.2)
- [x] 39. Oath of Light for Holy Paladins (2.5.2): on the main tank or a `/bb role` tank, else the player's target, then kept on whoever the player cast it on; never on the player or in PvP. Spell ID, duration and stacking are launch checks in TESTING.md
- [x] Blessing of Light removed: three blessings, no Light filler, a 4th Paladin is a reserve (2.5.1)
- [x] 29, part 2. Raid coordination for 2.5: roles, Greater Blessings with exceptions, slots shared out over add-on messages, `/bb role` and `/bb raid` (`d57f9d6`, `9999d4a`, `267d427`, `de356f9`, `4ea5463`; design in `docs/plan/SPEC.md`)
- [x] 21. Blessing of Light as the raid filler (`2a815e1`). Sanctuary isn't on the live servers, so there's nothing to add for it
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
