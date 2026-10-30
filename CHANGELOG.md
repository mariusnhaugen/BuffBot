# BuffBot

## 2.5.0

Massive Paladin buffing in raids release. TLDR: Automated role based coordination between several paladins.

Only works for paladins with it installed. Reconciliation for other classes and proper fallback planned for later releases, not really sure what I want the user experience to be yet.

### New

- **The cast keybind can now also be set on the settings page**, at the top, as
  well as under Key Bindings > AddOns.

- **BuffBot Paladins in a raid share out the blessings.** 
  They agree over add-on messages on one blessing each for the whole raid:
  - 2 paladins: Kings and Might or Wisdom (whichever the member's role wants);
  - 3 paladins: Kings, Wisdom and Might. Light as a fallback.
  - 4 paladins: gives Light, and any more wait quietly on the bench.
  - Each Paladin gives Light where their blessing does nothing. The self blessing is ignored in raids. 
  - Turning off "Buff your group" takes you out of the rotation: You only buff yourself (selfishly) and other paladins pick up your buff. (If there are any)

- **Smart targeting** The addon will try to optimize for fewest casts when dealing with exceptions, so 2 Resto druids and a Feral will get a Greater Blessing of Wisdom, and a prompt to Might the feral.
  Checks for Symbol of Kings or Reagent Economy before recommending Greaters. A class with one member, or mostly out of range, gets singles.
  
- **Buff Ordering**  
  - your own buffs 
  - Greater Blessings 
  - Singles (Exceptions to Greaters)

- **In a raid, blessings follow each member's role.** 
  - Tanks: Kings>Might>Light 
  - Melee: Might>Kings>Light 
  - Ranged (Hunters): Kings>Wisdom>Might>Light
  - Casters/Healers: Wisdom>Kings>Light

- **Spec detection attempts to determine roles, your own included.**
  Parties keep the class lists. A role comes from, in order:
  - Manual overrides using `/bb role` (below)
  - the main-tank mark, or the group's tank and healer roles
  - talent auras: Druids in Moonkin Form are casters, Druids with their
    own Leader of the Pack are melee.
  - talents, read by inspecting Druids, Shamans and Paladins (and Warriors
    when nobody is marked main tank) out of combat.

- **`/bb role <name> <role>`** 
  Where the spec detection has made a mistake, manual overrides are possible.
  the roles are: tank, melee, ranged, caster or healer e.g. `/bb role timmy melee` for a Feral Druid.
  `/bb role <name>` clears it. Roles are saved for your account.
  Sharing of manual overrides are coming in a future release. Hopefully the usefulness of this will diminish over time. 
- **`/bb raid`** shows which blessing each BuffBot Paladin gives, the
  Paladins not on BuffBot, and every raid member's role and where it came
  from.

### Changed

- "Buff your party" is now "Buff your group". In a raid it covers the whole
  raid, your own subgroup first. It's the one switch for buffing others.
- In battlegrounds and arenas, BuffBot only buffs you.

### Removed

- "Buff the whole raid". BuffBot now always covers the whole raid.

### Fixed

- The text under the button shows party members' full names, not only
  their first name.

## 2.4.0

### New

- **Multiple Paladins in a party now stack their blessings instead of all
  casting the same one.** When another Paladin's blessing is already on a
  member, you give them the next one on their class's list. Warriors and Rogues: Might, then
  Kings. Hunters and Paladins: Kings, then Wisdom, then Might. Druids and
  Shamans: Wisdom, then Kings, then Might. Priests, Mages and Warlocks:
  Wisdom, then Kings. Your own blessing starts with the one picked in the
  settings, then follows the Paladin list.

### Changed

- Only the buffs you cast are refreshed in their last 5 minutes. Someone
  else's buff, such as another Mage's Arcane Intellect, counts until it
  drops off.
- Your blessing on a member stays until it's due, then the button picks
  again. Learning Kings no longer has the button recast blessings that are
  still up.

## 2.3.0

### New

- **Group buffing.** The button also buffs party members who are missing
  Mark of the Wild, Arcane Intellect, Power Word: Fortitude or Divine
  Spirit, one press each. It buffs you first, then each member, one buff at
  a time.
- No mana wasted: members are skipped when they're dead, offline, out of
  range, or a class the buff does nothing for (no Arcane Intellect or Divine
  Spirit on Warriors and Rogues).
- **Group versions** (Gift of the Wild, Arcane Brilliance, Prayer of
  Fortitude, Prayer of Spirit) when two or more in the party are missing a
  buff and you have the Reagent Economy talent or the reagent.
- **Paladin blessings** on the party: Blessing of Might on Warriors and
  Rogues, Blessing of Kings on Hunters and Paladins once you have it,
  Blessing of Wisdom on everyone else. No Greater Blessings yet.
- In a raid, your own subgroup is buffed. "Buff the whole raid" carries on
  through the other subgroups. Off by default.
- The text under the button shows who a buff is for.

### Changed

- "Recommend Blessing of Wisdom" is now a "Paladin blessing on yourself"
  dropdown with Might, Wisdom and Kings. Your choice carries over.

## 2.2.0

### New

- **Righteous Fury** for Paladin tanks: turn on "Recommend Righteous Fury"
  in the settings. Off by default.
- **Tracking** comes back on by itself after you die and when you log in:
  Find Minerals, Find Herbs or a Hunter track, picked per character in the
  settings. Dwarves also get Find Treasure. Never in combat or in
  battlegrounds.

### Changed

- The settings page uses the game's own settings controls and tooltips.
  Your settings carry over.
- The button dims a little, as well as turning blue, when you're out of
  mana or rage.

### Fixed

- Lua errors about a "secret boolean value" in combat.

## 2.1.0

Era/SOD version ported to Forever, Weapon buffs and internationalisation.

### New

- **Rogue poisons:** a poison on each weapon, chosen per hand in the
  settings. Uses the highest rank in your bags, or another poison if you're
  out of the chosen one.
- **Shaman weapon imbues:** Rockbiter, Flametongue, Frostbrand or Windfury,
  chosen in the settings.
- Oils and sharpening stones count as weapon buffs, so they're never
  overwritten.
- Spell names follow your client's language.
- The icon turns blue when you're out of mana or rage.
- **Hide Icon** setting, for text-only buffing.

### Changed

- Ported to the WoW Forever client.
- The button hides while dead, a ghost or on a flight path.
- The text under the button always matches what the button will cast.
- With Bloodrage on, the button casts Bloodrage then Battle Shout out of
  combat, whatever your rage.
- Only your own Paladin aura counts.

### Known issues

- Group buffs (Gift of the Wild, Arcane Brilliance and so on) are untested in
  game, because the beta is levelcapped.
- Rogue stuff may be jank. 
