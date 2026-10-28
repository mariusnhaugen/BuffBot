local _, BuffBot = ...
local class = BuffBot.playerclass
local debug = BuffBot.debug

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

-- Buffs that cover each other: with any one up, the others aren't missing
local UniqueBuffsByClass = {}
UniqueBuffsByClass.HUNTER = { "Aspect of the Hawk", "Aspect of the Monkey", "Aspect of the Wild", "Aspect of the Beast" }
UniqueBuffsByClass.MAGE = { "Mage Armor", "Frost Armor", "Ice Armor" }
UniqueBuffsByClass.WARLOCK = { "Demon Skin", "Demon Armor" }
UniqueBuffsByClass.PALADIN = { "Devotion Aura", "Sanctity Aura", "Concentration Aura", "Retribution Aura",
    "Frost Resistance Aura", "Shadow Resistance Aura", "Fire Resistance Aura" }

-- Weapon enchants rather than auras, checked with BuffBot.HasWeaponEnchant
BuffBot.WeaponImbues = {
    ["Rockbiter Weapon"] = true,
    ["Flametongue Weapon"] = true,
    ["Frostbrand Weapon"] = true,
    ["Windfury Weapon"] = true,
}

BuffBot.WeaponPoisons = {
    ["Main Hand Poison"] = { invSlot = 16, weaponSlot = 0, setting = "ROGUE_POISON_MAINHAND" },
    ["Off Hand Poison"] = { invSlot = 17, weaponSlot = 1, setting = "ROGUE_POISON_OFFHAND" },
}

-- The blessings a Paladin can pick for themselves
BuffBot.SelfBlessings = { "Blessing of Might", "Blessing of Wisdom", "Blessing of Kings" }

-- Fallback order when the chosen poison runs out
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
for _, aura in ipairs(UniqueBuffsByClass.PALADIN) do
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
    ["Blessing of Kings"] = { "Greater Blessing of Kings" },
    ["Blessing of Light"] = { "Greater Blessing of Light" },
}

-- Single-target buffs the button also casts on group members
BuffBot.GroupBuffs = {
    ["Mark of the Wild"] = true,
    ["Arcane Intellect"] = true,
    ["Power Word: Fortitude"] = true,
    ["Divine Spirit"] = true,
    ["Blessing of Might"] = true,
    ["Blessing of Wisdom"] = true,
    ["Blessing of Kings"] = true,
    ["Blessing of Light"] = true,
}

-- Blessings by class, best first, for parties. A Paladin has one blessing on
-- each member, and blessings from different Paladins stack, so each Paladin
-- gives a member the first one on their list that nobody has given them yet.
-- Blessings not learned yet are skipped. The player's own starts with the one
-- picked in the settings, then follows the Paladin list. In a raid, members
-- follow their role's list instead (Roles.lua), and get Light once nothing on
-- it is left.
-- Greater Blessings wait for Paladins to share out blessings over add-on
-- messages.
BuffBot.Blessings = {
    ["Blessing of Might"] = true,
    ["Blessing of Wisdom"] = true,
    ["Blessing of Kings"] = true,
    ["Blessing of Light"] = true,
}
local MIGHT, WISDOM, KINGS, LIGHT = "Blessing of Might", "Blessing of Wisdom", "Blessing of Kings", "Blessing of Light"
BuffBot.BlessingPriority = {
    WARRIOR = { MIGHT, KINGS },
    ROGUE = { MIGHT, KINGS },
    HUNTER = { KINGS, WISDOM, MIGHT },
    PALADIN = { KINGS, WISDOM, MIGHT },
    DRUID = { WISDOM, KINGS, MIGHT },
    SHAMAN = { WISDOM, KINGS, MIGHT },
    PRIEST = { WISDOM, KINGS },
    MAGE = { WISDOM, KINGS },
    WARLOCK = { WISDOM, KINGS },
}

-- The aura of a blessing on a unit, or of its Greater Blessing, from anyone
local function BlessingAura(unit, blessing)
    local aura = C_UnitAuras.GetAuraDataBySpellName(unit, BuffBot.SpellName(blessing))
    if aura then return aura, false end
    for _, greater in ipairs(BuffBot.GroupVersions[blessing]) do
        aura = C_UnitAuras.GetAuraDataBySpellName(unit, BuffBot.SpellName(greater))
        if aura then return aura, true end
    end
end

-- Free to cast: learned, and not on the unit from another Paladin. The
-- player's own blessing counts as free, so a refresh can pick again.
local function BlessingFree(unit, blessing)
    if not BuffBot.CheckSpellAvailable(blessing) then return false end
    local aura = BlessingAura(unit, blessing)
    return aura == nil or aura.sourceUnit == "player"
end

-- The blessing each slot gives a member with this list: Might/Wisdom gives
-- whichever the list ranks higher. nil when it gives neither.
local SLOT_BLESSINGS = { K = KINGS, W = WISDOM, M = MIGHT, L = LIGHT }
local function SlotBlessing(slot, list)
    if slot ~= "MW" then return SLOT_BLESSINGS[slot] end
    local might, wisdom = BuffBot.IndexOf(MIGHT, list), BuffBot.IndexOf(WISDOM, list)
    if might and (not wisdom or might < wisdom) then return MIGHT end
    if wisdom then return WISDOM end
end

-- The blessing a member gets from the player while BuffBot Paladins share out
-- slots: the slot's blessing. When it does nothing for them, Light, unless
-- another Paladin holds Light's slot. When another Paladin (outside BuffBot)
-- already gave it, the next one on their list that no slot covers, then Light.
local function SlotBlessingFor(unit, list)
    local covered = {}
    for _, slot in ipairs(BuffBot.OtherSlots()) do
        local blessing = SlotBlessing(slot, list)
        if blessing then covered[blessing] = true end
    end
    local mine = SlotBlessing(BuffBot.MySlot(), list)
    if mine and (mine == LIGHT or BuffBot.IndexOf(mine, list)) then
        if BlessingFree(unit, mine) then return mine end
        for _, blessing in ipairs(list) do
            if not covered[blessing] and BlessingFree(unit, blessing) then return blessing end
        end
    end
    if not covered[LIGHT] and BlessingFree(unit, LIGHT) then return LIGHT end
end

-- The blessing a unit gets from the player, or nil when every blessing on
-- their list is learned by nobody or already given by other Paladins. The
-- player's blessing on them stands until it's due, then the list decides
-- again; on the player, the one picked in the settings takes over as soon as
-- it's free. A Greater Blessing went on for the class, not the member, so it
-- only counts when the list still picks it. In a raid, the list is the
-- member's role's, with Light last. With a slot among other BuffBot
-- Paladins, the slot decides, and the player is just another member.
function BuffBot.BlessingFor(unit)
    local inRaid = IsInRaid()
    local slotted = inRaid and BuffBot.Coordinating() and BuffBot.MySlot() ~= "-"
    local isPlayer = unit == "player" and not slotted
    local list = BuffBot.BlessingPriority[select(2, UnitClass(unit))] or {}
    if inRaid then
        list = BuffBot.RoleLists[BuffBot.RoleOf(unit)] or {}
    end
    if isPlayer then
        list = { BuffBot.config.PALADIN_BLESSING }
        for _, blessing in ipairs(BuffBot.BlessingPriority.PALADIN) do table.insert(list, blessing) end
    end
    for blessing in pairs(BuffBot.Blessings) do
        local aura, greater = BlessingAura(unit, blessing)
        if aura and aura.sourceUnit == "player" then
            local stands = not greater and BuffBot.UnitHasAssignedBuff(unit, blessing)
            local switch = isPlayer and blessing ~= list[1] and BlessingFree(unit, list[1])
            if stands and not switch then return blessing end
        end
    end
    if slotted then return SlotBlessingFor(unit, list) end
    if inRaid then
        list = { unpack(list) }
        table.insert(list, LIGHT)
    end
    for _, blessing in ipairs(list) do
        if BlessingFree(unit, blessing) then return blessing end
    end
end

-- Classes a buff does nothing for, so it's never cast on them (SKIP_LIST.md)
BuffBot.SkipOnClass = {
    ["Arcane Intellect"] = { WARRIOR = true, ROGUE = true },
    ["Divine Spirit"] = { WARRIOR = true, ROGUE = true },
    ["Blessing of Wisdom"] = { WARRIOR = true, ROGUE = true },
    ["Blessing of Might"] = { MAGE = true, PRIEST = true, WARLOCK = true },
}

-- Reagent item IDs per group version, any of which will do. Each rank wants
-- its own, but the button casts the highest rank known.
local reagents = {
    ["Gift of the Wild"] = { 17021, 17026 },    -- Wild Berries, Thornroot
    ["Arcane Brilliance"] = { 17020 },          -- Arcane Powder
    ["Prayer of Fortitude"] = { 17028, 17029 }, -- Holy Candle, Sacred Candle
    ["Prayer of Spirit"] = { 17029 },           -- Sacred Candle
    ["Greater Blessing of Might"] = { 21177 },  -- Symbol of Kings
    ["Greater Blessing of Wisdom"] = { 21177 },
    ["Greater Blessing of Kings"] = { 21177 },
    ["Greater Blessing of Light"] = { 21177 },
}

-- The account-wide Legacy talent that removes reagent costs. It's a trait,
-- not a spellbook spell or an aura, but IsPlayerSpell sees it (PROBE_RESULTS.md).
function BuffBot.HasReagentEconomy()
    return IsPlayerSpell(1225503)
end

local function HasReagent(groupVersion)
    for _, itemID in ipairs(reagents[groupVersion] or {}) do
        if C_Item.GetItemCount(itemID) > 0 then return true end
    end
    return false
end

-- The group version of a buff when the player can cast it, or nil
function BuffBot.CastableGroupVersion(buffString)
    local groupVersion = (BuffBot.GroupVersions[buffString] or {})[1]
    if not groupVersion or not BuffBot.CheckSpellAvailable(groupVersion) then return nil end
    if BuffBot.HasReagentEconomy() or HasReagent(groupVersion) then
        return groupVersion
    end
end

-- Every spell the add-on names, by rank 1 ID. The English names are only
-- keys: BuffBot.SpellName turns them into the client's names.
local spellIDTable = {
    --DRUID
    ["Omen of Clarity"] = 16864,
    ["Moonkin Form"] = 24858, -- talent auras, for raid roles
    ["Moonkin Aura"] = 24907,
    ["Leader of the Pack"] = 24932,
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
    ["Blessing of Kings"] = 20217,
    ["Greater Blessing of Kings"] = 25898,
    ["Blessing of Light"] = 19977, -- Classic IDs, unchecked on Forever
    ["Greater Blessing of Light"] = 25890,
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
}

function BuffBot.SpellID(spellString)
    return spellIDTable[spellString]
end


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

-- The player's unique buffs under the current settings
BuffBot.uniqueBuffs = {}
local function FilterUniqueBuffs()
    local buffs = UniqueBuffsByClass[class] or {}
    if class == "HUNTER" and not BuffBot.config.CHEETAH_REMINDER then
        -- Copy so the base list is never mutated between rebuilds
        buffs = { unpack(buffs) }
        table.insert(buffs, "Aspect of the Cheetah")
        table.insert(buffs, "Aspect of the Pack")
    end
    -- Strict armors: only the recommended armor counts
    if class == "MAGE" and BuffBot.config.STRICT_ARMOR then
        buffs = {}
    end
    BuffBot.uniqueBuffs = buffs
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
            -- The chosen blessing, or Might until it's learned
            spellString = BuffBot.config.PALADIN_BLESSING
            if not BuffBot.CheckSpellAvailable(spellString) then
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
