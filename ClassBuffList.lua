local _, BuffBot = ...
BuffBot.config = {}
local class = BuffBot.playerclass
local function debug() end
debug = BuffBot.debug

local InitalClassBuffLists = {}
InitalClassBuffLists.DRUID = { "Omen of Clarity", "Mark of the Wild", "Thorns" }
InitalClassBuffLists.HUNTER = { "Trueshot Aura", "Aspect of the Hawk" }
InitalClassBuffLists.MAGE = { "Unique", "Arcane Intellect", "Dampen Magic" }
InitalClassBuffLists.PALADIN = { "Unique", "Blessing" }
InitalClassBuffLists.PRIEST = { "Power Word: Fortitude", "Shadowform", "Divine Spirit", "Inner Fire" }
InitalClassBuffLists.ROGUE = {}
InitalClassBuffLists.SHAMAN = { "Lightning Shield" }
InitalClassBuffLists.WARLOCK = { "Unique" }
InitalClassBuffLists.WARRIOR = { "Battle Shout" }

local UniqueBuffs = {}
BuffBot.UniqueBuffs = {}
UniqueBuffs.HUNTER = { "Aspect of the Hawk", "Aspect of the Monkey", "Aspect of the Wild", "Aspect of the Beast" }
UniqueBuffs.MAGE = { "Mage Armor", "Frost Armor", "Ice Armor" }
UniqueBuffs.WARLOCK = { "Demon Skin", "Demon Armor" }
UniqueBuffs.PALADIN = { "Devotion Aura", "Sanctity Aura", "Concentration Aura", "Retribution Aura",
    "Frost Resistance Aura", "Shadow Resistance Aura", "Fire Resistance Aura" }

-- Auras every Paladin in the group can provide; only the player's own count
BuffBot.OwnOnlyBuffs = {}
for _, aura in ipairs(UniqueBuffs.PALADIN) do
    BuffBot.OwnOnlyBuffs[aura] = true
end

-- Every spell the add-on names, by rank 1 ID. The English names are only
-- keys: BuffBot.SpellName turns them into the client's names.
local spellIDTable = {
    --DRUID
    ["Omen of Clarity"] = 16864,
    ["Mark of the Wild"] = 1126,
    ["Gift of the Wild"] = 21849,
    ["Thorns"] = 467,
    --HUNTER
    ["Trueshot Aura"] = 19506,
    ["Aspect of the Hawk"] = 13165,
    ["Aspect of the Monkey"] = 13163,
    ["Aspect of the Wild"] = 20043,
    ["Aspect of the Beast"] = 13161,
    ["Aspect of the Cheetah"] = 5118,
    ["Aspect of the Pack"] = 13159,
    --MAGE
    ["Frost Armor"] = 168, -- Low level
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
    -- PRIEST
    ["Power Word: Fortitude"] = 1243,
    ["Prayer of Fortitude"] = 21562,
    ["Shadowform"] = 15473,
    ["Divine Spirit"] = 14752,
    ["Prayer of Spirit"] = 27681,
    ["Inner Fire"] = 588,
    -- ROGUE
    -- SHAMAN
    ["Lightning Shield"] = 324,
    -- WARLOCK
    ["Demon Skin"] = 687, -- Low level
    ["Demon Armor"] = 706,
    -- WARRIOR
    ["Battle Shout"] = 6673,
    ["Bloodrage"] = 2687,
}


-- The client's name for a spell key. ID lookups resolve on every client and
-- names don't change in a session, so they're cached.
local spellNames = {}
function BuffBot.SpellName(spellString)
    local name = spellNames[spellString]
    if name then return name end
    local spellID = spellIDTable[spellString]
    local info = spellID and C_Spell.GetSpellInfo(spellID)
    if not info then return spellString end
    spellNames[spellString] = info.name
    return info.name
end

function BuffBot.CheckSpellAvailable(spellString)
    local spellID = spellIDTable[spellString]
    if not spellID then return end
    -- Some spells replace their lower ranks, so IsPlayerSpell(rank 1) can be
    -- false while a higher rank is known. Name lookups resolve the highest
    -- known rank, so look up rank 1's name by ID and find it in the spellbook.
    local info = C_Spell.GetSpellInfo(spellID)
    return info ~= nil and C_Spell.GetSpellInfo(info.name) ~= nil
end

local function FilterUniqueBuffs()
    if class == "WARLOCK" then
        BuffBot.UniqueBuffs.WARLOCK = UniqueBuffs.WARLOCK
    end
    if class == "PALADIN" then
        BuffBot.UniqueBuffs.PALADIN = UniqueBuffs.PALADIN
    end

    if class == "HUNTER" then
        -- Copy so the base list is never mutated between rebuilds
        local aspects = { unpack(UniqueBuffs.HUNTER) }
        if not BuffBot.config.CHEETAH_REMINDER then
            table.insert(aspects, "Aspect of the Cheetah")
            table.insert(aspects, "Aspect of the Pack")
        end
        BuffBot.UniqueBuffs.HUNTER = aspects
    end

    if class == "MAGE" then
        if BuffBot.config.STRICT_ARMOR then
            BuffBot.UniqueBuffs.MAGE = nil
        else
            BuffBot.UniqueBuffs.MAGE = UniqueBuffs.MAGE
        end
    end
end

local function RecommendUniqueBuff()
    if BuffBot.playerclass == "MAGE" then
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
        if spellString == "Thorns" and BuffBot.config.IGNORE_THORNS then
            debug("Skipping thorns")
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
    FilterUniqueBuffs()
    local FilteredClassBuffList = {}
    for i = 1, #InitalClassBuffLists[BuffBot.playerclass], 1 do
        local spellString = InitalClassBuffLists[BuffBot.playerclass][i]
        if spellString == "Unique" then
            spellString = RecommendUniqueBuff()
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
            debug(InitalClassBuffLists[BuffBot.playerclass][i] .. " not found or intentionally skipped")
        end
    end
    BuffBot.classBuffList = FilteredClassBuffList
end
