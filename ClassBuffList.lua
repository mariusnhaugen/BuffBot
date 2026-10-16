local _, BuffBot = ...
BuffBot.config = {}
local class = BuffBot.playerclass
local function debug() end
debug = BuffBot.debug

local InitalClassBuffLists = {}
InitalClassBuffLists.DRUID = { "Omen of Clarity", "Mark of the Wild", "Thorns" }
InitalClassBuffLists.HUNTER = { "Trueshot Aura", "Aspect of the Hawk" }
InitalClassBuffLists.MAGE = { "Unique", "Arcane Intellect", "Dampen Magic" }
InitalClassBuffLists.PALADIN = { "Unique", "Blessing", "Righteous Fury" }
InitalClassBuffLists.PRIEST = { "Power Word: Fortitude", "Shadowform", "Divine Spirit", "Inner Fire" }
InitalClassBuffLists.ROGUE = { "Main Hand Poison", "Off Hand Poison" }
InitalClassBuffLists.SHAMAN = { "Lightning Shield", "Imbue" }
InitalClassBuffLists.WARLOCK = { "Unique" }
InitalClassBuffLists.WARRIOR = { "Battle Shout" }

local UniqueBuffs = {}
BuffBot.UniqueBuffs = {}
UniqueBuffs.HUNTER = { "Aspect of the Hawk", "Aspect of the Monkey", "Aspect of the Wild", "Aspect of the Beast" }
UniqueBuffs.MAGE = { "Mage Armor", "Frost Armor", "Ice Armor" }
UniqueBuffs.WARLOCK = { "Demon Skin", "Demon Armor" }
UniqueBuffs.PALADIN = { "Devotion Aura", "Sanctity Aura", "Concentration Aura", "Retribution Aura",
    "Frost Resistance Aura", "Shadow Resistance Aura", "Fire Resistance Aura" }

-- Weapon enchants rather than auras, checked with BuffBot.HasWeaponEnchant
BuffBot.WeaponImbues = {
    ["Rockbiter Weapon"] = true,
    ["Flametongue Weapon"] = true,
    ["Frostbrand Weapon"] = true,
    ["Windfury Weapon"] = true,
}

-- Poisons are items, one per hand, and checked like imbues. invSlot is the
-- equipment slot, weaponSlot the slot for C_Item.GetWeaponEnchantInfo.
BuffBot.WeaponPoisons = {
    ["Main Hand Poison"] = { invSlot = 16, weaponSlot = 0, setting = "ROGUE_POISON_MAINHAND" },
    ["Off Hand Poison"] = { invSlot = 17, weaponSlot = 1, setting = "ROGUE_POISON_OFFHAND" },
}

-- Also the fallback order when the chosen poison runs out
BuffBot.PoisonTypes = { "Instant Poison", "Deadly Poison", "Crippling Poison", "Mind-numbing Poison", "Wound Poison" }

-- Item IDs for each poison by rank, lowest first
local poisonItemIDs = {
    ["Instant Poison"] = { 6947, 6949, 6950, 8926, 8927, 8928 },
    ["Deadly Poison"] = { 2892, 2893, 8984, 8985, 20844 },
    ["Crippling Poison"] = { 3775, 3776 },
    ["Mind-numbing Poison"] = { 5237, 6951, 9186 },
    ["Wound Poison"] = { 10918, 10920, 10921, 10922 },
}

local function HighestRankInBags(poison)
    local ranks = poisonItemIDs[poison] or {}
    for i = #ranks, 1, -1 do
        if C_Item.GetItemCount(ranks[i]) > 0 then return ranks[i] end
    end
end

-- The client's name for a poison, from its rank 1 item. Item names can be
-- missing until the item is cached, so it falls back to the English name.
function BuffBot.PoisonName(poison)
    return C_Item.GetItemNameByID(poisonItemIDs[poison][1]) or poison
end

-- The item ID for a hand: the highest rank of the chosen poison in the bags,
-- or of the first other poison there is. nil with no poison at all.
function BuffBot.PoisonItem(handKey)
    local chosen = BuffBot.config[BuffBot.WeaponPoisons[handKey].setting]
    local item = HighestRankInBags(chosen)
    if item then return item end
    for _, poison in ipairs(BuffBot.PoisonTypes) do
        item = HighestRankInBags(poison)
        if item then return item end
    end
end

-- Auras every Paladin in the group can provide; only the player's own count
BuffBot.OwnOnlyBuffs = {}
for _, aura in ipairs(UniqueBuffs.PALADIN) do
    BuffBot.OwnOnlyBuffs[aura] = true
end

-- Group versions that cover a single-target buff
BuffBot.GroupVersions = {
    ["Mark of the Wild"] = { "Gift of the Wild" },
    ["Arcane Intellect"] = { "Arcane Brilliance" },
    ["Power Word: Fortitude"] = { "Prayer of Fortitude" },
    ["Divine Spirit"] = { "Prayer of Spirit" },
    ["Blessing of Might"] = { "Greater Blessing of Might" },
    ["Blessing of Wisdom"] = { "Greater Blessing of Wisdom" },
}

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
    ["Righteous Fury"] = 25780,
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
    ["Rockbiter Weapon"] = 8017,
    ["Flametongue Weapon"] = 8024,
    ["Frostbrand Weapon"] = 8033,
    ["Windfury Weapon"] = 8232,
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

-- The client's name for a list entry: the poison's item name, or the spell's
function BuffBot.DisplayName(key)
    if BuffBot.WeaponPoisons[key] then
        local item = BuffBot.PoisonItem(key)
        return item and C_Item.GetItemNameByID(item) or key
    end
    return BuffBot.SpellName(key)
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

    -- Only tanks want the extra threat
    if class == "PALADIN" then
        if spellString == "Righteous Fury" and not BuffBot.config.RIGHTEOUS_FURY then
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
        if spellString == "Imbue" then
            -- The chosen imbue, or Rockbiter until it's learned
            spellString = BuffBot.config.SHAMAN_IMBUE
            if not BuffBot.CheckSpellAvailable(spellString) then
                spellString = "Rockbiter Weapon"
            end
        end
        if spellString == "Blessing" then
            if BuffBot.config.WISDOM_SELF then
                spellString = "Blessing of Wisdom"
            else
                spellString = "Blessing of Might"
            end
        end

        local skipSpell = GetSpellSkip(spellString)
        -- Poisons are items, so whether there are any is checked on each update
        local available = BuffBot.WeaponPoisons[spellString] or BuffBot.CheckSpellAvailable(spellString)

        if available and not skipSpell then
            debug(spellString, " Added to Filtered List")
            table.insert(FilteredClassBuffList, spellString)
        else
            debug(InitalClassBuffLists[BuffBot.playerclass][i] .. " not found or intentionally skipped")
        end
    end
    BuffBot.classBuffList = FilteredClassBuffList
end
