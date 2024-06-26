local _, BuffBot = ...
local ParentFrame;
local macroBtn;
local events = CreateFrame("Frame")
local groupHasChanged = false

BuffBot.playername = GetUnitName("player")
BuffBot.playerlevel = UnitLevel("player")
BuffBot.playerclass = (select(2, UnitClass("player")))

local classBuffs = BuffBot.classBuffs 
local assignedBuff = "" 

    SLASH_BUFFBOTSETTINGS1 = "/bb";
    SLASH_BUFFBOTSETTINGS2 = "/buffbot";
    SlashCmdList.BUFFBOTSETTINGS = function(arg)
        if arg == "" then arg = "player" end
       
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

    function UpdateMacro(buffString,unit)
        if InCombatLockdown() then return end
        macroBtn:SetNormalTexture(GetSpellTexture(buffString))
        macroBtn:SetAttribute("macrotext1", "/cast [target="..unit.."]" .. buffString) -- text for macro on left click
        macroBtn:Show()
    end

--------------- MAIN FUNCTIONS ----------------

function SetInitialClassBuff()
    assignedBuff = classBuffs[BuffBot.playerclass][1]
    if not CheckUnitHasAssignedBuff("player", assignedBuff) then
        UpdateMacro(assignedBuff,"player")
    end
end

function FindNextBuffInList()
    if InCombatLockdown() then return "done" end
    for i = 1, #classBuffs[BuffBot.playerclass], 1 do
    if not CheckUnitHasAssignedBuff("player", classBuffs[BuffBot.playerclass][i]) then
            return classBuffs[BuffBot.playerclass][i]
            end
        end
    macroBtn:Hide()
    return "done" 
end

function CheckPlayerBuffs() 
        local buff = FindNextBuffInList()
        if buff == "done" then return end
        assignedBuff = buff
        UpdateMacro(assignedBuff, "player")
end

function CheckUnitHasAssignedBuff(unit, assignedBuff)
    if assignedBuff == "" then return end
    
    local aura = C_UnitAuras.GetAuraDataBySpellName(unit, assignedBuff)
    if aura then 
        return true
    else
        return false
    end
end


------------- EVENT FUNCTIONS -------------

function events:UNIT_AURA(unit, info)  
    if info.isFullUpdate then -- triggers when new group memebers join
        -- if groupHasChanged then
        --     CheckUnitHasAssignedBuff("party1", assignedBuff)
        --     groupHasChanged = false
        -- end
		return
	end
    if info.removedAuraInstanceIDs then
        if (unit == "player") then
           CheckPlayerBuffs() 
        end
        return
    end
        
    if (unit == "player") then
        CheckPlayerBuffs() 
        return
    end

    local substr = string.sub(unit, 1,4)
    if (substr == "raid") or (substr == "part")  then
        -- print(unit)    
    end
    -- 
end

function events:GROUP_JOINED()
end

function events:GROUP_ROSTER_UPDATE()
    -- CheckUnitHasAssignedBuff("player", assignedBuff)
    -- if UnitExists("party1")  then
    --     groupHasChanged = true
    --     return
    -- end
    -- if UnitExists("raid1") then
    --     groupHasChanged = true
    --     return
    -- end
    return
end

function events:GROUP_LEFT()
	print("Group left")
    -- scan friends :)
end

function events:PLAYER_ENTERING_WORLD()
    SetInitialClassBuff()
end

function events:UNIT_SPELLCAST_SUCCEEDED(unit)
    if not (unit == "player") then return end 
        CheckPlayerBuffs() 
end

function events:PLAYER_REGEN_ENABLED()
    CheckPlayerBuffs()
end


function events:PLAYER_REGEN_DISABLED()
    macroBtn:Hide()
end

events:SetScript("OnEvent", function(self, event, ...)
	self[event](self, ...)
end)

events:RegisterEvent("UNIT_AURA")
events:RegisterEvent("GROUP_JOINED")
events:RegisterEvent("GROUP_ROSTER_UPDATE")
events:RegisterEvent("GROUP_LEFT")
events:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterEvent("PLAYER_ENTERING_WORLD")

print("BuffBot v0.0.1 Loaded.")
print(BuffBot.playername .." "..  BuffBot.playerlevel .." ".. BuffBot.playerclass)

function CastCurrentButtonBuff()
    
end