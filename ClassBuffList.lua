local _, BuffBot = ...

local FilteredClassBuffList = {}
local InitalClassBuffLists = {}
InitalClassBuffLists.DRUID= {"Omen of Clarity","Mark of the Wild", "Thorns"}
InitalClassBuffLists.HUNTER = {"Heart of the Lion","Trueshot Aura","Aspect of the Hawk"}
InitalClassBuffLists.MAGE = {"Mage Armor", "Arcane Intellect", "Dampen Magic"}
InitalClassBuffLists.PALADIN = {"Devotion Aura" ,"Blessing of Might"}
InitalClassBuffLists.PRIEST = {"Power Word: Fortitude","Shadowform","Divine Spirit", "Inner Fire"}
InitalClassBuffLists.ROGUE = {}
InitalClassBuffLists.SHAMAN = {"Lightning Shield"}
InitalClassBuffLists.WARLOCK= {"Demon Armor" ,"Grimoire of Synergy",}
InitalClassBuffLists.WARRIOR = { "Battle Shout","Commanding Shout"}

local spellIDTable = { -- Rank 1 for checking.
--DRUID
    ["Omen of Clarity"] = 16864,
    ["Mark of the Wild"] = 5232,
    ["Thorns"] = 782,
--HUNTER
    ["Heart of the Lion"] = 409580,
    ["Trueshot Aura"] = 19506,
    ["Aspect of the Hawk"] = 13165,
--MAGE
    ["Frost Armor"] = 168, -- Low level
    ["Ice Armor"] = 7302,
    ["Mage Armor"] = 6117,
    ["Arcane Intellect"] = 1459,
    ["Dampen Magic"] = 604,
-- PALADIN
    ["Devotion Aura"] = 10290,
    ["Blessing of Might"] = 19740,
    ["Blessing of Wisdom"] = 19742,
-- PRIEST 
    ["Power Word: Fortitude"] = 1243,
    ["Shadowform"] = 15473,
    ["Divine Spirit"] = 14752,
    ["Inner Fire"] = 588,
-- ROGUE
-- SHAMAN
    ["Lightning Shield"] = 324,
-- WARLOCK
    ["Demon Armor"] = 706,
    ["Demon Skin"] = 687, -- Low level
    ["Fel Armor"] = 403619,
    ["Grimoire of Synergy"] = 426301,
-- WARRIOR
    ["Battle Shout"] = 6673,
    ["Commanding Shout"] = 403215,
}

function CheckSpellAvailable(spellString)
    if spellString == "" then return end
    local spellID = spellIDTable[spellString]
    if spellID then
        return IsSpellKnown(spellID)
    end
end

function FilterInitialList()
    for i = 1, #InitalClassBuffLists[BuffBot.playerclass], 1 do
        local spellstring = InitalClassBuffLists[BuffBot.playerclass][i]

        if CheckSpellAvailable(spellstring) then
            table.insert(FilteredClassBuffList, spellstring)
        else
            print(InitalClassBuffLists[BuffBot.playerclass][i] .. " not found. Skipped") 
        end
    end
    BuffBot.ClassBuffList = FilteredClassBuffList 
end

