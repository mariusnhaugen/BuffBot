local _, BuffBot = ...
local events = CreateFrame("Frame")
local groupHasChanged = false
local class = BuffBot.playerclass

function events:UNIT_AURA(unit, info)  
    if info.isFullUpdate then 
        -- triggers when people join party or player zones through instance
        if (unit == "player") then
            if UnitInRaid("player") then BuffBot:UpdateClassBuffList() end
        end
        if groupHasChanged then
            print("Group changed")
            groupHasChanged = false
        end
		return
	end
    if info.removedAuraInstanceIDs then
        if (unit == "player") then
           BuffBot:CheckPlayerBuffs() 
        end
        return
    end
        
    if (unit == "player") then
        BuffBot:CheckPlayerBuffs() 
        return
    end

    local substr = string.sub(unit, 1,4)
    if (substr == "raid") or (substr == "part")  then
        -- print(unit)    
    end
    -- 
end


function events:GROUP_ROSTER_UPDATE()
        BuffBot:UpdateClassBuffList()
        groupHasChanged = true
end

function events:GROUP_LEFT()

        BuffBot:UpdateClassBuffList()
end

function events:SPELLS_CHANGED()
    BuffBot:UpdateClassBuffList()
end

function events:UNIT_SPELLCAST_SUCCEEDED(unit)
    if not (unit == "player") then return end 
    BuffBot:CheckPlayerBuffs() 
end

function events:PLAYER_REGEN_ENABLED()
    BuffBot:CheckPlayerBuffs()
end

function events:PLAYER_REGEN_DISABLED()
    BuffBot.macroBtn:Hide()
end

events:SetScript("OnEvent", function(self, event, ...)
	self[event](self, ...)
end)

events:RegisterEvent("UNIT_AURA")

events:RegisterEvent("GROUP_ROSTER_UPDATE")
events:RegisterEvent("GROUP_LEFT")

events:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")

events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("PLAYER_REGEN_DISABLED")

events:RegisterEvent("SPELLS_CHANGED")
