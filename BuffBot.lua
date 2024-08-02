local addonName, BuffBot = ...

local class = BuffBot.playerclass
local classBuffs = {}
local assignedBuff = ""

SLASH_BUFFBOTSETTINGS1 = "/bb";
SLASH_BUFFBOTSETTINGS2 = "/buffbot";
SlashCmdList.BUFFBOTSETTINGS = function(arg)
    if arg == "" then
        if InterfaceOptionsFrame_OpenToCategory then
            InterfaceOptionsFrame_OpenToCategory(addonName)
        end
    end
    if arg == "buffs" then
        DevTools_Dump(classBuffs)
        return
    end

    if arg == "debug" then
        BuffBot.config.DEBUG_MODE = not BuffBot.config.DEBUG_MODE
        print("BuffBot Debug Mode -", BuffBot.config.DEBUG_MODE)
        return
    end
end

--------------- MAIN FUNCTIONS ----------------

function BuffBotDump()
    return BuffBot.RanklessSpells
end

function BuffBot.UpdateClassBuffList()
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

function BuffBot.SkipCheck(i)
    if (BuffBot.UniqueBuffs[class] ~= nil) then
        if BuffBot.IndexOf(classBuffs[i], BuffBot.UniqueBuffs[class]) then
            if BuffBot.HasUniqueClassBuff() then return true end -- check auras and armors
        end
    end
    if class == "DRUID" then
        if classBuffs[i] == "Mark of the Wild" then
            return BuffBot.UnitHasAssignedBuff("player", "Gift of the Wild")
        end
    end
    if class == "PRIEST" then
        if classBuffs[i] == "Power Word: Fortitude" then
            return BuffBot.UnitHasAssignedBuff("player", "Prayer of Fortitude")
        end
    end
    if class == "WARLOCK" then
        if classBuffs[i] == "Grimoire of Synergy" then
            if not IsPetActive() then return true end
        end
    end
    if class == "WARRIOR" then
        if classBuffs[i] == "Battle Shout" then
            if not IsUsableSpell("Battle Shout") and not BuffBot.config.BLOODRAGE then return true end
            if not IsUsableSpell("Battle Shout") and BuffBot.config.BLOODRAGE and (not BuffBot.UnitHasAssignedBuff("player", "Battle Shout")) then
                if BuffBot.CheckSpellAvailable("Bloodrage") and (not BuffBot.IndexOf("Bloodrage", classBuffs)) and not BuffBot.BLOODRAGE_LOCKED then
                    BuffBot.debug("Bloodrage Added")
                    local bsIndex = BuffBot.IndexOf("Battle Shout", classBuffs)
                    table.insert(classBuffs, bsIndex, "Bloodrage")
                end
            end
        end
        if classBuffs[i] == "Commanding Shout" then
            return BuffBot.UnitHasAssignedBuff("player", "Blood Pact")
        end
        if classBuffs[i] == "Valor of Azeroth" then
            return BuffBot.UnitHasAssignedBuff("player", "Rallying Cry of the Dragonslayer")
        end
    end
end

function BuffBot.FindNextBuffInList()
    if InCombatLockdown() then return "done" end
    if classBuffs == nil then return "done" end

    for i = 1, #classBuffs do                  -- For all buffs in filtered buff list.
        local skipCheck = BuffBot.SkipCheck(i) -- check for exceptions
        if (not BuffBot.UnitHasAssignedBuff("player", classBuffs[i])) and (not skipCheck) then
            return classBuffs[i]
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

function BuffBot.UnitHasAssignedBuff(unit, assignedBuff)
    if assignedBuff == "" then return end

    local aura = C_UnitAuras.GetAuraDataBySpellName(unit, assignedBuff)
    if aura then
        return true
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
