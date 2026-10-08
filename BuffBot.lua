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

function BuffBotDump()
    return BuffBot.RanklessSpells
end

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

local function RecommendOtherPaladinBuff(buffString)
    if buffString == "" then return end

    -- for aura: GetShapeshiftForm() returns 0 for no aura, 1 for Devotion
    --when this function is called, the existence of one of the buff has already been checked
    -- Check if the origin is player, and suggest alternate buff.
    if BuffBot.BuffIsFromPlayer(buffString) then
        --TODO: CheckSpellAvailable
        if IsInGroup() then
            return "Blessing of Salvation"
        else
            if buffString == "Blessing of Wisdom" then
                return "Blessing of Might"
            else
                return "Blessing of Wisdom"
            end
        end
    end
end

local function ShouldSkipBuff(buffString)
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
    if class == "WARRIOR" then
        if buffString == "Battle Shout" then
            if not C_Spell.IsSpellUsable("Battle Shout") and not BuffBot.config.BLOODRAGE then return true end
            if not C_Spell.IsSpellUsable("Battle Shout") and BuffBot.config.BLOODRAGE and (not BuffBot.UnitHasAssignedBuff("player", "Battle Shout")) then
                if BuffBot.CheckSpellAvailable("Bloodrage") and (not BuffBot.IndexOf("Bloodrage", classBuffs)) and not BuffBot.BLOODRAGE_LOCKED then
                    BuffBot.debug("Bloodrage Added")
                    local bsIndex = BuffBot.IndexOf("Battle Shout", classBuffs)
                    table.insert(classBuffs, bsIndex, "Bloodrage")
                end
            end
        end
    end
end

function BuffBot.FindNextBuffInList()
    if InCombatLockdown() then return "done" end
    if classBuffs == nil then return "done" end

    for i = 1, #classBuffs do                   -- For all buffs in filtered buff list.
        local currentBuff = classBuffs[i]
        if not ShouldSkipBuff(currentBuff) then -- check for exceptions
            if (not BuffBot.UnitHasAssignedBuff("player", currentBuff)) then
                BuffBot.debug(currentBuff, " Missing.")
                return currentBuff
                -- else
                --     if class == "PALADIN" then
                --         if currentBuff == "Blessing of Wisdom" or currentBuff == "Blessing of Might" then
                --             local newBuff = RecommendOtherPaladinBuff(currentBuff)
                --             if newBuff then
                --                 return newBuff
                --             end
                --         end
                --     end
            end
        end
    end
    return "done"
end

function BuffBot.CheckPlayerBuffs()
    local buff = BuffBot.FindNextBuffInList()
    if buff == "done" then
        if InCombatLockdown() then return end
        BuffBot.macroButton:Hide()
        return
    end
    assignedBuff = buff
    BuffBot.UpdateMacro(assignedBuff, "player")

    if BuffBot.config.SUGGESTION_LIST then
        BuffBot.UpdateSuggestionList()
    end
end

function BuffBot.UnitHasAssignedBuff(unit, buffString)
    if buffString == "" then return end

    local filter = BuffBot.OwnOnlyBuffs[buffString] and "HELPFUL|PLAYER" or nil
    local aura = C_UnitAuras.GetAuraDataBySpellName(unit, buffString, filter)
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

function BuffBot.BuffIsFromPlayer(buffString)
    if buffString == "" then return end

    local aura = C_UnitAuras.GetAuraDataBySpellName("player", buffString)
    if aura ~= nil then
        return aura.isFromPlayerOrPlayerPet
    else
        return false
    end
end

function BuffBot.RemoveBloodrage()
    local index = BuffBot.IndexOf("Bloodrage", classBuffs)
    if index then
        table.remove(classBuffs, index)
        return true
    end
    return false
end
