# BuffBot

## 2.5.0

### New

- **In a raid, blessings follow each member's role.** Warriors and Rogues
  are melee (Might, then Kings), Hunters ranged (Kings, Wisdom, Might),
  Mages and Warlocks casters, and Priests, Druids, Shamans and Paladins
  healers (Wisdom, then Kings). Parties keep the class lists. Main-tank
  marked members are tanks (Kings, then Might), and so are the group's
  tank roles. Druids in Moonkin Form are casters, and Druids with their own
  Leader of the Pack are melee (Might, then Kings). Other Druids, Shamans
  and Paladins (and Warriors, when nobody is marked main tank) are
  inspected out of combat, one every 1.5 seconds, to read their talents.
  Your own role comes from your talents.
- **`/bb role <name> <role>`** sets a raid member's role (tank, melee,
  ranged, caster or healer), e.g. `/bb role oak melee` for a Feral Druid.
  `/bb role <name>` clears it.
- **Greater Blessings in a raid.** One per class, for the blessing most of
  the class gets, then single blessings for members who need a different
  one, such as a Feral Druid among Restos. Needs Symbol of Kings or Reagent
  Economy. A class with one member, or mostly out of range, gets singles.
  The order: your own buffs, then the Greater Blessings, the class missing
  the most first, then the singles.
- **BuffBot Paladins in a raid share out the blessings.** They agree over
  add-on messages on one blessing each for the whole raid: with two, Kings
  and Might/Wisdom (by role); with three, Kings, Wisdom and Might; a fourth
  gives Light. Each Paladin gives Light where their blessing does nothing.
  The button just shows the next cast; there's nothing to set up. Your
  self-blessing setting is ignored while you share out blessings.
- **Blessing of Light** fills in for raid members who already have every
  blessing on their list from other Paladins.

### Changed

- "Buff your party" is now "Buff your group". In a raid it covers the whole
  raid, your own subgroup first. It's the one switch for buffing others.
- In battlegrounds and arenas, BuffBot only buffs you.

### Removed

- "Buff the whole raid". BuffBot now always covers the whole raid.

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
