local _, BuffBot = ...
local events = CreateFrame("Frame")

function events:UNIT_AURA(unit, info)  
    if info.isFullUpdate then 
        -- triggers when people join party or player zones through instance

        if (unit == "player") then
           CheckPlayerBuffs() 
        end
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
    BuffBot.macroBtn:Hide()
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
