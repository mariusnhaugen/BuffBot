local _, BuffBot = ...

local class = BuffBot.playerclass
local classBuffs = {}
local assignedBuff = ""
local REMINDER_DURA_MULTIPLIER = 0.2 -- aura.Duration * REMINDER_DURA_MULTIPLIER to get reminder duration

-- Group versions that cover a single-target buff
local GROUP_VERSIONS = {
    ["Mark of the Wild"] = { "Gift of the Wild" },
    ["Arcane Intellect"] = { "Arcane Brilliance" },
    ["Power Word: Fortitude"] = { "Prayer of Fortitude" },
    ["Divine Spirit"] = { "Prayer of Spirit" },
    ["Blessing of Might"] = { "Greater Blessing of Might" },
    ["Blessing of Wisdom"] = { "Greater Blessing of Wisdom" },
}

--------------- MAIN FUNCTIONS ----------------

function BuffBot.UpdateClassBuffList()
    BuffBot.debug("UpdateClassBuffList")
    BuffBot.FilterInitialList()
    classBuffs = BuffBot.classBuffList
    BuffBot.CheckPlayerBuffs()
end

function BuffBot.HasUniqueClassBuff()
    for i = 1, #BuffBot.UniqueBuffs[class], 1 do
        if BuffBot.UnitHasAssignedBuff("player", BuffBot.UniqueBuffs[class][i]) then
            return true
        end
    end
    return false
end

-- With the option on, Battle Shout always tries Bloodrage first out of combat,
-- whatever the rage: rage drains without an event, so a macro picked by rage
-- goes stale. The next press falls through to Battle Shout. In combat the
-- Bloodrage line is skipped, so keybind presses don't error on its cooldown.
local function BloodrageFirst(buffString)
    if class ~= "WARRIOR" or buffString ~= "Battle Shout" then return false end
    return BuffBot.config.BLOODRAGE and BuffBot.CheckSpellAvailable("Bloodrage")
end

local INVSLOT_MAINHAND = 16

local function ShouldSkipBuff(buffString)
    -- An imbue needs a main-hand weapon
    if BuffBot.WeaponImbues[buffString] and not GetInventoryItemID("player", INVSLOT_MAINHAND) then
        return true
    end
    if (BuffBot.UniqueBuffs[class] ~= nil) then
        if BuffBot.IndexOf(buffString, BuffBot.UniqueBuffs[class]) then
            if BuffBot.HasUniqueClassBuff() then return true end -- check auras and armors
        end
    end
    local groupVersions = GROUP_VERSIONS[buffString]
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
    if classBuffs == nil then return missing end

    for i = 1, #classBuffs do
        local currentBuff = classBuffs[i]
        if not ShouldSkipBuff(currentBuff) and not BuffBot.UnitHasAssignedBuff("player", currentBuff) then
            table.insert(missing, currentBuff)
        end
    end
    return missing
end

function BuffBot.FindNextBuffInList()
    local buff = BuffBot.MissingBuffs()[1]
    if not buff then return "done" end
    BuffBot.debug(buff, " Missing.")
    return buff
end

function BuffBot.CheckPlayerBuffs()
    local buff = BuffBot.FindNextBuffInList()
    if buff == "done" then
        if InCombatLockdown() then return end
        BuffBot.macroButton:Hide()
        return
    end
    assignedBuff = buff
    BuffBot.UpdateMacro(assignedBuff, "player", BloodrageFirst(assignedBuff) and "Bloodrage" or nil)

    if BuffBot.config.SUGGESTION_LIST then
        BuffBot.UpdateSuggestionList()
    end
end

-- Enum.WeaponSlot.MainHand, and Enum.ItemEnchantType's Temporary (oils and
-- stones) and Imbue (Shaman). Permanent enchants don't count.
local WEAPON_MAINHAND = 0
local ENCHANT_TEMPORARY, ENCHANT_IMBUE = 2, 3

-- Any temporary enchant counts, so an oil isn't overwritten with an imbue
function BuffBot.HasWeaponEnchant()
    for _, enchant in ipairs(C_Item.GetWeaponEnchantInfo(WEAPON_MAINHAND) or {}) do
        local temporary = enchant.enchantType == ENCHANT_TEMPORARY or enchant.enchantType == ENCHANT_IMBUE
        -- Expiring like a buff: under 5 minutes left (timeLeft is in ms)
        if enchant.hasEnchant and temporary and enchant.timeLeft >= 300000 then
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
