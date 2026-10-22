# Skip list

Buffs that do nothing (or almost nothing) for some classes, based on Classic Era (patch 1.12) rules. With a skip list, BuffBot won't report these buffs as missing on those classes.

Only single-target buffs are listed, since the caster picks who gets them. Auras, totems, shouts and group buffs (Arcane Brilliance, Prayer of Spirit, Greater Blessings) are left out because the caster can't choose who they land on.

## The list

| Buff | Caster | Skip on | Why |
|---|---|---|---|
| Arcane Intellect | Mage | Warrior, Rogue | No mana |
| Blessing of Wisdom | Paladin | Warrior, Rogue | No mana |
| Blessing of Might | Paladin | Mage, Priest, Warlock | Only adds melee attack power |
| Divine Spirit | Priest | Warrior, Rogue | Spirit only gives them health regen outside combat (nearly useless) |

## Optional

| Buff | Skip on | Why |
|---|---|---|
| Blessing of Might | Hunter | Only melee attack power counts, and Hunters do almost no melee damage |

## Not on the list

- **Auras** (Trueshot Aura, Leader of the Pack, Moonkin Aura, Paladin auras): they cover the whole party.
- **Totems and Battle Shout**: they cover the whole party.
- **Innervate and Power Infusion**: left out on purpose.
- **Group versions of buffs**: they cover the whole party, raid or class.

## Depends on spec, not class

The skip list only looks at class, so these aren't on it:

- **Blessing of Salvation** is harmful on tanks (Protection Warrior, Bear Druid, Protection Paladin).
- **Blessing of Might** does nothing for Resto/Balance Druids, Holy Paladins and Resto/Elemental Shamans.
- **Spirit and Wisdom** still help feral Druids, who need mana to shift forms.
