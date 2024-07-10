local _, BuffBot = ...
local ParentFrame;
local macroBtn;

local class = BuffBot.playerclass

local classBuffs = {}
local assignedBuff = "" 

    SLASH_BUFFBOTSETTINGS1 = "/bb";
    SLASH_BUFFBOTSETTINGS2 = "/buffbot";
    SlashCmdList.BUFFBOTSETTINGS = function(arg)
        if arg == "" then return end
      
        if arg == "buffs" then
            DevTools_Dump(classBuffs)
            return
        end
        print(assignedBuff)
        local aura = C_UnitAuras.GetAuraDataBySpellName(arg, assignedBuff)
        if aura then 
            print(GetUnitName(arg).. " is buffed with " .. assignedBuff)
            return true
        else
            print(GetUnitName(arg) .. " does not have " .. assignedBuff )
            return false
        end
     
    end
---------------- UI ---------------------------    
    macroBtn = CreateFrame("Button", "BUFFBOT_MacroButton", UIParent, "SecureActionButtonTemplate")
    _G["BINDING_NAME_" .. "CLICK BUFFBOT_MacroButton:LeftButton"] = "BuffBot Cast"
    macroBtn:SetAttribute("type1", "macro") -- left click causes macro
    macroBtn:SetSize(48,48)
    macroBtn:SetPoint("CENTER", ParentFrame, "CENTER", 100, 0)


--------------- MAIN FUNCTIONS ----------------
    
function BuffBotDump()
 return BuffBot.RanklessSpells
end

function BuffBot:UpdateMacro(buffString,unit)
        if InCombatLockdown() then return end
        local texture = GetSpellTexture(buffString)
        if texture then
            macroBtn:SetNormalTexture(texture)
        end
        macroBtn:SetAttribute("macrotext1", "/cast [target="..unit.."]" .. buffString) -- text for macro on left click
        macroBtn:Show()
    end

function BuffBot:UpdateClassBuffList()
    BuffBot:FilterInitialList()
    classBuffs = BuffBot.ClassBuffList 
    BuffBot:CheckPlayerBuffs()
end

function BuffBot:HasUniqueClassBuff()
    local isBuffFound = false
    for i = 1, #BuffBot.UniqueBuffs[class], 1 do 
        if BuffBot:UnitHasAssignedBuff("player", BuffBot.UniqueBuffs[class][i]) then
            isBuffFound = true 
            break
        end
    end
    return isBuffFound
end

function BuffBot:FindNextBuffInList()
    if InCombatLockdown() then return "done" end
    if not classBuffs then return "done" end

    for i = 1, #classBuffs do -- For all buffs in filtered buff list. 
        local skipCheck = false;
        if class == "MAGE" or class == "WARLOCK" or class == "PALADIN" then
            if BuffBot:StringIsPartOfTable(classBuffs[i], BuffBot.UniqueBuffs[class]) then
                if BuffBot:HasUniqueClassBuff() then skipCheck = true end -- check auras and armors
            end
        end
        if class == "WARLOCK" then
            if classBuffs[i] == "Grimoire of Synergy" then
                if not IsPetActive() then skipCheck = true end
            end
            
        end

        if (not BuffBot:UnitHasAssignedBuff("player", classBuffs[i])) and (not skipCheck) then
            return classBuffs[i]
        end
    end
    return "done" 
end

function BuffBot:CheckPlayerBuffs() 
        local buff = BuffBot:FindNextBuffInList()
        if buff == "done" then 
            if InCombatLockdown() then return end
            macroBtn:Hide()
            return 
        end
        assignedBuff = buff
        BuffBot:UpdateMacro(assignedBuff, "player")
end

function BuffBot:UnitHasAssignedBuff(unit, assignedBuff)
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



print("BuffBot v0.0.3 Loaded.")