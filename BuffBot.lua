local _, BuffBot = ...
local ParentFrame;
local macroBtn;


local class = BuffBot.playerclass

local classBuffs = {}
BuffBot.futureBuffStrings = {}
local assignedBuff = "" 

    SLASH_BUFFBOTSETTINGS1 = "/bb";
    SLASH_BUFFBOTSETTINGS2 = "/buffbot";
    SlashCmdList.BUFFBOTSETTINGS = function(arg)
        if arg == "" then return end
      
        if arg == "buffs" then
            DevTools_Dump(classBuffs)
            return
        end

        if arg == "debug" then
            BuffBot.DEBUG_MODE = not BuffBot.DEBUG_MODE
            print("BuffBot Debug Mode -", BuffBot.DEBUG_MODE)
            return
        end
     
    end
---------------- UI ---------------------------    
    macroBtn = CreateFrame("Button", "BUFFBOT_MacroButton", UIParent, "SecureActionButtonTemplate")
    _G["BINDING_NAME_" .. "CLICK BUFFBOT_MacroButton:LeftButton"] = "BuffBot Cast"
    macroBtn:SetAttribute("type1", "macro") -- left click causes macro
    macroBtn:SetSize(48,48)
    macroBtn:SetPoint("CENTER", ParentFrame, "CENTER", 100, 0)

    BuffBot.suggestionList = {}
    function BuffBot.UpdateSuggestionList()
        if #BuffBot.suggestionList then
           for i = 1, #BuffBot.suggestionList, 1 do
                BuffBot.suggestionList[i]:SetText("")
                BuffBot.suggestionList[i]:Hide()
           end 
        end

        if not BuffBot.config.SUGGESTION_LIST then return end
        if #classBuffs > 0 then
            local nextIndex = BuffBot.IndexOf(BuffBot.FindNextBuffInList(), classBuffs)
            BuffBot.futureBuffStrings = {unpack(classBuffs,nextIndex,#classBuffs)}
            
            FilterSuggestionList()
   
           for i = 1, #BuffBot.futureBuffStrings, 1 do
            local offset = -35 + (i*-15)
            if (not BuffBot.suggestionList[i]) and (i <= 5) then
                BuffBot.suggestionList[i] = macroBtn:CreateFontString(nil, "OVERLAY", "GameTooltipText")
                BuffBot.suggestionList[i]:SetPoint("TOPLEFT", macroBtn, 0, offset)
            end
                BuffBot.suggestionList[i]:SetText(BuffBot.futureBuffStrings[i])
                BuffBot.suggestionList[i]:Show()
           end 
        end
    end

    function FilterSuggestionList()
        local filteredTable = {}
        for i = 1, #BuffBot.futureBuffStrings, 1 do
            if not BuffBot.UnitHasAssignedBuff("player", BuffBot.futureBuffStrings[i]) then
                table.insert(filteredTable, BuffBot.futureBuffStrings[i])
            end
        end 
        BuffBot.futureBuffStrings = filteredTable
    end
    --------------- MAIN FUNCTIONS ----------------
    
function BuffBotDump()
 return BuffBot.RanklessSpells
end

function BuffBot.UpdateMacro(buffString,unit)
        if InCombatLockdown() then return end
        local texture = GetSpellTexture(buffString)
        if texture then
            macroBtn:SetNormalTexture(texture)
        end
        macroBtn:SetAttribute("macrotext1", "/cast [target="..unit.."]" .. buffString) -- text for macro on left click
        macroBtn:Show()
    end

function BuffBot.UpdateClassBuffList()
    BuffBot.FilterInitialList()
    classBuffs = BuffBot.ClassBuffList 
    BuffBot.CheckPlayerBuffs()
end

function BuffBot.HasUniqueClassBuff()
    local isBuffFound = false
    for i = 1, #BuffBot.UniqueBuffs[class], 1 do 
        if BuffBot.UnitHasAssignedBuff("player", BuffBot.UniqueBuffs[class][i]) then
            isBuffFound = true 
            break
        end
    end
    return isBuffFound
end

function BuffBot.SkipCheck(i)
        if class == "MAGE" or class == "WARLOCK" or class == "PALADIN" or class == "HUNTER" then
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
                if not IsUsableSpell("Battle Shout") then return true end
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
    if not classBuffs then return "done" end

    for i = 1, #classBuffs do -- For all buffs in filtered buff list. 
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
            macroBtn:Hide()
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

--- Namespacing  ---
BuffBot.macroBtn = macroBtn;



print("BuffBot v0.0.4 Loaded.")