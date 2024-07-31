local _, BuffBot = ...
local events = CreateFrame("Frame")
local groupHasChanged = false
local class = BuffBot.playerclass
local function debug() end
debug = BuffBot.debug

function events:UNIT_AURA(unit, info)  
    if info.isFullUpdate then 
        -- triggers when people join party or player zones through instance
        if (unit == "player") then
            if UnitInRaid("player") then BuffBot.UpdateClassBuffList() end
        end
        if groupHasChanged then
            debug("Group changed")
            groupHasChanged = false
        end
		return
	end
    if info.removedAuraInstanceIDs then
        if (unit == "player") then
           BuffBot.CheckPlayerBuffs() 
        end
        return
    end
        
    if (unit == "player") then
        BuffBot.CheckPlayerBuffs() 
        return
    end
end


function events:GROUP_ROSTER_UPDATE()
        BuffBot.UpdateClassBuffList()
        groupHasChanged = true
end

function events:GROUP_LEFT()
        BuffBot.UpdateClassBuffList()
end

function events:SPELLS_CHANGED()
    BuffBot.UpdateClassBuffList()
end

function events:UNIT_SPELLCAST_SUCCEEDED(unit)
    if not (unit == "player") then return end 
    BuffBot.CheckPlayerBuffs() 
end

function events:PLAYER_REGEN_ENABLED()
    BuffBot.CheckPlayerBuffs()
end

function events:PLAYER_REGEN_DISABLED()
    BuffBot.macroBtn:Hide()
end

function events:ADDON_LOADED()
    if BuffBotConfig == nil then
       BuffBotConfig = BuffBot.GetDefaultConfig() 
    end
    BuffBot.config = BuffBotConfig
end

function events:PLAYER_LOGOUT()
    BuffBotConfig = BuffBot.config 
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

--Fired when Spellbook is populated. On login as well as overrides changing (runes)
events:RegisterEvent("SPELLS_CHANGED")

events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGOUT")