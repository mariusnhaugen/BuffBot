local _, BuffBot = ...
local class = BuffBot.playerclass
local function debug() end
debug = BuffBot.debug

local InitalClassBuffLists = {}
InitalClassBuffLists.DRUID= {"Omen of Clarity","Mark of the Wild", "Thorns"}
InitalClassBuffLists.HUNTER = {"Heart of the Lion","Trueshot Aura","Aspect of the Hawk"}
InitalClassBuffLists.MAGE = {"Unique", "Arcane Intellect", "Dampen Magic"}
InitalClassBuffLists.PALADIN = {"Unique" ,"Blessing"}
InitalClassBuffLists.PRIEST = {"Power Word: Fortitude","Shadowform","Divine Spirit", "Inner Fire"}
InitalClassBuffLists.ROGUE = {}
InitalClassBuffLists.SHAMAN = {"Lightning Shield"}
InitalClassBuffLists.WARLOCK= {"Unique" ,"Grimoire of Synergy",}
InitalClassBuffLists.WARRIOR = {"Valor of Azeroth","Commanding Shout", "Battle Shout"}

BuffBot.UniqueBuffs = {}
BuffBot.UniqueBuffs.HUNTER = {"Aspect of the Viper", "Aspect of the Hawk", "Aspect of the Pack", "Aspect of the Monkey", "Aspect of the Cheetah", "Aspect of the Wild", "Aspect of the Beast" }
BuffBot.UniqueBuffs.MAGE = {"Mage Armor", "Frost Armor", "Molten Armor", "Ice Armor"}
BuffBot.UniqueBuffs.WARLOCK = {"Demon Skin", "Demon Armor", "Fel Armor"}
BuffBot.UniqueBuffs.PALADIN= {"Devotion Aura", "Sanctity Aura", "Concentration Aura", "Retribution Aura", "Frost Resistance Aura", "Shadow Resistance Aura", "Fire Resistance Aura"}

BuffBot.RanklessSpells = {} -- Spells that prevent downranking and require special lookup calls
BuffBot.RanklessSpells = BuffBot.UniqueBuffs.PALADIN
table.insert(BuffBot.RanklessSpells,1 , "Battle Shout")


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
    ["Molten Armor"] = 428741,
    ["Arcane Intellect"] = 1459,
    ["Dampen Magic"] = 604,
-- PALADIN
    ["Devotion Aura"] = 465,
    ["Sanctity Aura"] = 20218,
    ["Concentration Aura"] = 19746,
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
    ["Demon Skin"] = 687, -- Low level
    ["Demon Armor"] = 706,
    ["Fel Armor"] = 403619,
    ["Grimoire of Synergy"] = 426301,
    ["Blood Pact"] = 11767,
-- WARRIOR
    ["Battle Shout"] = 6673,
    ["Commanding Shout"] = 403215,
    ["Valor of Azeroth"] = 461475,
    ["Bloodrage"] = 2687,
}


function BuffBot.CheckSpellAvailable(spellString)
    if spellString == "" then return end
    local spellID = spellIDTable[spellString]

    if class == "PALADIN" or class == "WARRIOR" then
        if BuffBot.IndexOf(spellString, BuffBot.RanklessSpells) then
            if  GetSpellInfo(GetSpellInfo(spellID)) then --get local name of R1, and find Spell id
                return true
            else return false end
        end
    end
    
    if #tostring(spellID) == 6 then
        return IsSpellKnownOrOverridesKnown(spellID)
    end
    if spellID then
        return IsPlayerSpell(spellID)
    end
end

function BuffBot.RecommendUniqueBuff()
    if BuffBot.playerclass == "MAGE" then
        if BuffBot.CheckSpellAvailable("Molten Armor") then
            return "Molten Armor"
        end
        if BuffBot.CheckSpellAvailable("Mage Armor") and IsInRaid(LE_PARTY_CATEGORY_HOME) then
            return "Mage Armor"
        end
        if BuffBot.CheckSpellAvailable("Ice Armor") then
            return "Ice Armor"
        end
        if BuffBot.CheckSpellAvailable("Frost Armor") then
            return "Frost Armor"
        end
    end

    if BuffBot.playerclass == "WARLOCK" then
        if BuffBot.CheckSpellAvailable("Fel Armor") and UnitInRaid("player") then
            return "Fel Armor"
        end
        if BuffBot.CheckSpellAvailable("Demon Armor") then
            return "Demon Armor"
        end
        if BuffBot.CheckSpellAvailable("Demon Skin") then
            return "Demon Skin"
        end
    end
    if BuffBot.playerclass == "PALADIN" then
        if BuffBot.CheckSpellAvailable("Sanctity Aura") then
            return "Sanctity Aura"
        end
        if BuffBot.CheckSpellAvailable("Devotion Aura") then
            return "Devotion Aura"
        end
        if BuffBot.CheckSpellAvailable("Retribution Aura") then
            return "Retribution Aura"
        end
    end
end

local function GetSpellSkip(spellString)
    
    if class == "DRUID" then
        if spellString == "Thorns"and BuffBot.config.IGNORE_THORNS then
            return true
        end
    end

    if class == "MAGE" then
        if spellString == "Dampen Magic" and BuffBot.config.IGNORE_DAMPEN then
            return true
        end
    end

    return false
end

function BuffBot.FilterInitialList()
    local FilteredClassBuffList = {}
    for i = 1, #InitalClassBuffLists[BuffBot.playerclass], 1 do
        local spellString = InitalClassBuffLists[BuffBot.playerclass][i]
        if spellString == "Unique" then
            spellString = BuffBot.RecommendUniqueBuff()
        end
        if spellString == "Blessing" then
            if BuffBot.config.WISDOM_SELF then 
                spellString = "Blessing of Wisdom"
            else
                spellString = "Blessing of Might"
            end
        end

        local skipSpell = GetSpellSkip(spellString)

        if BuffBot.CheckSpellAvailable(spellString) and not skipSpell then
            debug(spellString, " Added to Filtered List")
            table.insert(FilteredClassBuffList, spellString)
        else
            debug(InitalClassBuffLists[BuffBot.playerclass][i] .. " not found. Skipped") 
        end
    end
    BuffBot.ClassBuffList = FilteredClassBuffList 
end

