# BuffBot

Maintenance buffs made easy. BuffBot puts a single button on your screen that
casts the next self-buff you're missing. Press it until it disappears and
you're fully buffed.

Made for **WoW Forever**. The Classic Era version is no longer updated.

## How it works

- The button shows the next missing buff. A press casts it, and the button
  moves on once the buff lands.
- The text under the button lists what's still missing.
- A buff counts as missing when it's not on you, or when it's about to run
  out (under 5 minutes and under a fifth of its duration left).
- The button hides in combat, while dead or a ghost, and on a flight path.
  The keybind still works when the button is hidden.
- The icon turns blue when you don't have the mana or rage to cast it.
- Spell names follow your client's language.

## Classes

| Class | Buffs |
|---|---|
| Druid | Omen of Clarity, Mark of the Wild, Thorns |
| Hunter | Trueshot Aura, Aspect of the Hawk (any other combat aspect also counts) |
| Mage | Ice Armor or Frost Armor (Mage Armor in a raid), Arcane Intellect, Dampen Magic |
| Paladin | An aura (Sanctity, Devotion or Retribution), Blessing of Might, Wisdom or Kings, Righteous Fury if you tank. Party members get a blessing by class, shared out with other Paladins |
| Priest | Power Word: Fortitude, Shadowform, Divine Spirit, Inner Fire |
| Rogue | A poison on each weapon |
| Shaman | Lightning Shield, a weapon imbue |
| Warlock | Demon Armor or Demon Skin |
| Warrior | Battle Shout, with Bloodrage first if you want |

Buffs you haven't learned are skipped, and a single-target buff is skipped
while its group version (such as Gift of the Wild) is on you.

**Group buffing:** Mark of the Wild, Arcane Intellect, Power Word: Fortitude,
Divine Spirit and Paladin blessings also go on your party, one press per
member, after you. Each class has a list of blessings, best first:
Warriors and Rogues Might then Kings, Hunters and Paladins Kings then Wisdom
then Might, Druids and Shamans Wisdom then Kings then Might, and Priests,
Mages and Warlocks Wisdom then Kings. A member gets the first one no other
Paladin has given them, so blessings from several Paladins stack. Kings comes
at level 20.
Members who are dead, offline or out of range are skipped, and so are
classes a buff does nothing for (see [SKIP_LIST.md](SKIP_LIST.md)). When two
or more are missing a buff and you have the Reagent Economy talent or the
reagent, the button casts the group version instead. In a raid it buffs your
own subgroup, or the whole raid if you turn that on. Pets can't be buffed in
Forever.

**Weapon buffs:** an oil or a sharpening stone on the weapon also counts, so
BuffBot won't ask you to overwrite it. Rogues get the highest rank of the
chosen poison in their bags, or another poison if they have none of it, and
a poison running low on charges counts as missing.

## Setup

- **Keybind:** Key Bindings > AddOns > BuffBot Cast. A key you can press
  repeatedly is the fastest way to buff.
- **Move the button:** hold Alt and drag it.
- **Settings:** `/bb` or `/buffbot`.

## Settings

- **Hide Icon / Hide Text:** text-only or icon-only buffing.
- **Reset Button Position.**
- **Buff your party:** group buffing, on by default.
- **Buff the whole raid:** after your subgroup, the rest of the raid. Off by
  default.
- **Strict Mage Armors:** only the recommended armor counts.
- **Skip Dampen Magic / Skip Thorns.**
- **Always try Bloodrage out of combat:** casts Bloodrage before Battle Shout.
- **Paladin blessing on yourself:** Might, Wisdom or Kings. Might until the
  one you pick is learned. If another Paladin has already put it on you, you
  get the next one on the Paladin list.
- **Recommend Righteous Fury:** for Paladin tanks. Off by default.
- **Reminder to leave Cheetah:** shows Aspect of the Hawk while you're in
  Cheetah or Pack.
- **Shaman weapon imbue:** Rockbiter, Flametongue, Frostbrand or Windfury.
- **Rogue poisons:** one for each hand.

`/bb buffs` prints your current buff list.

## Development

See [TESTING.md](TESTING.md) for the tests and the open in-game checks,
[PROBE_RESULTS.md](PROBE_RESULTS.md) for the finished ones, and
[TODO.md](TODO.md) for open work. Releases are built from a `v*` tag by the
BigWigs packager, with notes from [CHANGELOG.md](CHANGELOG.md).
