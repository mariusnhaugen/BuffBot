local _, BuffBot = ...

local class = BuffBot.playerclass
local REMINDER_DURA_MULTIPLIER = 0.2 -- aura.Duration * REMINDER_DURA_MULTIPLIER to get reminder duration

--------------- MAIN FUNCTIONS ----------------

function BuffBot.UpdateClassBuffList()
    BuffBot.debug("UpdateClassBuffList")
    BuffBot.FilterInitialList()
    BuffBot.CheckPlayerBuffs()
end

function BuffBot.HasUniqueClassBuff()
    for i = 1, #BuffBot.uniqueBuffs, 1 do
        if BuffBot.UnitHasAssignedBuff("player", BuffBot.uniqueBuffs[i]) then
            return true
        end
    end
    return false
end

local function ShouldBloodrageFirst(buffString)
    if class ~= "WARRIOR" or buffString ~= "Battle Shout" then return false end
    return BuffBot.config.BLOODRAGE and BuffBot.CheckSpellAvailable("Bloodrage")
end

local INVSLOT_MAINHAND = 16

local function ShouldSkipBuff(buffString)
    -- An imbue needs a main-hand weapon
    if BuffBot.WeaponImbues[buffString] and not GetInventoryItemID("player", INVSLOT_MAINHAND) then
        return true
    end
    -- A poison needs a weapon in that hand and a poison in the bags
    local poison = BuffBot.WeaponPoisons[buffString]
    if poison and not (GetInventoryItemID("player", poison.invSlot) and BuffBot.PoisonItem(buffString)) then
        return true
    end
    if BuffBot.IndexOf(buffString, BuffBot.uniqueBuffs) and BuffBot.HasUniqueClassBuff() then
        return true -- check auras and armors
    end
    local groupVersions = BuffBot.GroupVersions[buffString]
    if groupVersions then
        for i = 1, #groupVersions do
            if BuffBot.UnitHasAssignedBuff("player", groupVersions[i]) then return true end
        end
    end
end

-- Every buff the button would cast, in order. The button casts the first, and
-- the suggestion list shows them all.
function BuffBot.MissingBuffs()
    local missing = {}
    if InCombatLockdown() then return missing end
    if UnitIsDeadOrGhost("player") or UnitOnTaxi("player") then return missing end
    local classBuffs = BuffBot.classBuffList
    if classBuffs == nil then return missing end

    for i = 1, #classBuffs do
        local currentBuff = classBuffs[i]
        if not ShouldSkipBuff(currentBuff) and not BuffBot.UnitHasAssignedBuff("player", currentBuff) then
            table.insert(missing, currentBuff)
        end
    end
    return missing
end

function BuffBot.CheckPlayerBuffs()
    local missing = BuffBot.MissingBuffs()
    local buff = missing[1]
    if not buff then
        if InCombatLockdown() then return end
        BuffBot.macroButton:Hide()
        return
    end
    BuffBot.debug(buff, " Missing.")
    local poison = BuffBot.WeaponPoisons[buff]
    if poison then
        BuffBot.UpdateItemMacro(BuffBot.PoisonItem(buff), poison.invSlot)
    else
        BuffBot.UpdateMacro(buff, "player", ShouldBloodrageFirst(buff) and "Bloodrage" or nil)
    end

    BuffBot.UpdateSuggestionList(missing)
end

local WEAPON_MAINHAND = 0                     --0,1,2 are mh,oh,ranged
local ENCHANT_TEMPORARY, ENCHANT_IMBUE = 2, 3 --enchantType
local LOW_CHARGES = 10

-- Any temporary enchant counts, so an rsham oil isn't overwritten with an imbue.
function BuffBot.HasWeaponEnchant(weaponSlot)
    for _, enchant in ipairs(C_Item.GetWeaponEnchantInfo(weaponSlot or WEAPON_MAINHAND) or {}) do
        local temporary = enchant.enchantType == ENCHANT_TEMPORARY or enchant.enchantType == ENCHANT_IMBUE
        -- Expiring like a buff: under 5 minutes left (timeLeft is in ms), or
        -- low on charges. Enchants without charges report 0.
        local expiring = enchant.timeLeft < 300000 or (enchant.charges > 0 and enchant.charges < LOW_CHARGES)
        if enchant.hasEnchant and temporary and not expiring then
            return true
        end
    end
    return false
end

function BuffBot.UnitHasAssignedBuff(unit, buffString)
    if buffString == "" then return end
    if BuffBot.WeaponImbues[buffString] then
        return unit == "player" and BuffBot.HasWeaponEnchant()
    end
    local poison = BuffBot.WeaponPoisons[buffString]
    if poison then
        return unit == "player" and BuffBot.HasWeaponEnchant(poison.weaponSlot)
    end

    local filter = BuffBot.OwnOnlyBuffs[buffString] and "HELPFUL|PLAYER" or nil
    local aura = C_UnitAuras.GetAuraDataBySpellName(unit, BuffBot.SpellName(buffString), filter)
    if aura ~= nil then
        if (aura.duration > 0) and (aura.expirationTime > 0) then
            local timeLeft = aura.expirationTime - GetTime()
            if (timeLeft < aura.duration * REMINDER_DURA_MULTIPLIER) and (timeLeft < 300) then
                return false
            end
        end
        return true
    else
        return false
    end
end
