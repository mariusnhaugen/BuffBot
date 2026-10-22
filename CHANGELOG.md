# BuffBot

## 2.3.0 (unreleased)

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
