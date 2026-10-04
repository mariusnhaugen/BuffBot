-- Spell name <-> ID table for the fake game. Covers every spell the addon
-- looks up by ID plus the auras it checks by name.
local byName = {
    -- DRUID
    ["Omen of Clarity"] = 16864,
    ["Mark of the Wild"] = 5232,
    ["Gift of the Wild"] = 21849,
    ["Thorns"] = 782,
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
    -- PRIEST
    ["Power Word: Fortitude"] = 1243,
    ["Prayer of Fortitude"] = 21562,
    ["Shadowform"] = 15473,
    ["Divine Spirit"] = 14752,
    ["Inner Fire"] = 588,
    -- SHAMAN
    ["Lightning Shield"] = 324,
    -- WARLOCK
    ["Demon Skin"] = 687,
    ["Demon Armor"] = 706,
    -- WARRIOR
    ["Battle Shout"] = 6673,
    ["Bloodrage"] = 2687,
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

function Spells.iconOf(name)
    return "Interface\\Icons\\" .. name
end

return Spells
