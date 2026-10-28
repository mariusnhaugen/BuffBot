-- Spell name <-> ID table for the fake game. Covers every spell the addon
-- looks up by ID plus the auras it checks by name.
local byName = {
    -- DRUID
    ["Omen of Clarity"] = 16864,
    ["Mark of the Wild"] = 1126,
    ["Gift of the Wild"] = 21849,
    ["Thorns"] = 467,
    -- HUNTER
    ["Trueshot Aura"] = 19506,
    ["Aspect of the Hawk"] = 13165,
    ["Aspect of the Monkey"] = 13163,
    ["Aspect of the Wild"] = 20043,
    ["Aspect of the Beast"] = 13161,
    ["Aspect of the Cheetah"] = 5118,
    ["Aspect of the Pack"] = 13159,
    -- MAGE
    ["Frost Armor"] = 168,
    ["Ice Armor"] = 7302,
    ["Mage Armor"] = 6117,
    ["Arcane Intellect"] = 1459,
    ["Arcane Brilliance"] = 23028,
    ["Dampen Magic"] = 604,
    -- PALADIN
    ["Devotion Aura"] = 465,
    ["Sanctity Aura"] = 20218,
    ["Concentration Aura"] = 19746,
    ["Retribution Aura"] = 7294,
    ["Frost Resistance Aura"] = 19888,
    ["Shadow Resistance Aura"] = 19876,
    ["Fire Resistance Aura"] = 19891,
    ["Blessing of Might"] = 19740,
    ["Blessing of Wisdom"] = 19742,
    ["Greater Blessing of Might"] = 25782,
    ["Greater Blessing of Wisdom"] = 25894,
    ["Blessing of Kings"] = 20217,
    ["Greater Blessing of Kings"] = 25898,
    ["Blessing of Light"] = 19977,
    ["Greater Blessing of Light"] = 25890,
    ["Righteous Fury"] = 25780,
    -- PRIEST
    ["Power Word: Fortitude"] = 1243,
    ["Prayer of Fortitude"] = 21562,
    ["Shadowform"] = 15473,
    ["Divine Spirit"] = 14752,
    ["Prayer of Spirit"] = 27681,
    ["Inner Fire"] = 588,
    -- SHAMAN
    ["Lightning Shield"] = 324,
    ["Rockbiter Weapon"] = 8017,
    ["Flametongue Weapon"] = 8024,
    ["Frostbrand Weapon"] = 8033,
    ["Windfury Weapon"] = 8232,
    -- WARLOCK
    ["Demon Skin"] = 687,
    ["Demon Armor"] = 706,
    -- WARRIOR
    ["Battle Shout"] = 6673,
    ["Bloodrage"] = 2687,
    -- TRACKING
    ["Find Minerals"] = 2580,
    ["Find Herbs"] = 2383,
    ["Find Treasure"] = 2481,
    ["Track Beasts"] = 1494,
    ["Track Humanoids"] = 19883,
    ["Track Undead"] = 19884,
    ["Track Hidden"] = 19885,
    ["Track Elementals"] = 19880,
    ["Track Demons"] = 19878,
    ["Track Giants"] = 19882,
    ["Track Dragonkin"] = 19879,
    -- Legacy perk, a trait rather than a spellbook spell
    ["Reagent Economy"] = 1225503,
}

local byID = {}
for name, id in pairs(byName) do
    byID[id] = name
end

local Spells = {}

function Spells.idOf(name)
    return byName[name]
end

function Spells.nameOf(id)
    return byID[id]
end

function Spells.names()
    local names = {}
    for name in pairs(byName) do table.insert(names, name) end
    return names
end

function Spells.iconOf(name)
    return "Interface\\Icons\\" .. name
end

return Spells
