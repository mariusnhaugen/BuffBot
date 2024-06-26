local _, BuffBot = ...

local InitalClassBuffLists = {}
InitalClassBuffLists.DRUID= {"Omen of Clarity","Mark of the Wild", "Thorns"}
InitalClassBuffLists.HUNTER = {"Heart of the Lion","Trueshot Aura","Aspect of the Hawk"}
InitalClassBuffLists.MAGE = {"Mage Armor", "Arcane Intellect", "Dampen Magic"}
InitalClassBuffLists.PALADIN = {"Devotion Aura" ,"Blessing of Might"}
InitalClassBuffLists.PRIEST = {"Power Word: Fortitude","Shadowform","Divine Spirit", "Inner Fire"}
InitalClassBuffLists.ROGUE = {}
InitalClassBuffLists.SHAMAN = {}
InitalClassBuffLists.WARLOCK= {"Demon Armor" ,"Grimoire of Synergy",}
InitalClassBuffLists.WARRIOR = { "Battle Shout","Commanding Shout"}

BuffBot.ClassBuffList = InitalClassBuffLists