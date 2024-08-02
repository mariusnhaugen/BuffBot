local addonName, BuffBot = ...
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

function events:UNIT_SPELLCAST_SUCCEEDED(unit, _, spellID)
    if (unit ~= "player") then return end
    if spellID == 2687 then --Bloodrage
        BuffBot.BLOODRAGE_LOCKED = true
        if BuffBot.RemoveBloodrage() then
            BuffBot.UpdateMacro("Battle Shout", "player")
        end
    end
    if spellID == select(7, GetSpellInfo(GetSpellInfo(6673))) then --Battle shout
        debug("Battle Shout Cast")
        if BuffBot.BLOODRAGE_LOCKED then
            BuffBot.BLOODRAGE_LOCKED = false
        end
    end
    BuffBot.CheckPlayerBuffs()
end

function events:PLAYER_REGEN_ENABLED()
    BuffBot.CheckPlayerBuffs()
end

function events:PLAYER_REGEN_DISABLED()
    BuffBot.macroButton:Hide()
end

function events:ADDON_LOADED(arg1)
    if (arg1 ~= addonName) then return end

    if BuffBotConfig == nil then
        BuffBotConfig = BuffBot.GetDefaultConfig()
    end
    BuffBot.config = BuffBotConfig


    local debugString = ""
    if BuffBot.config.DEBUG_MODE then
        debugString = " - DEBUG MODE ON"
    end
    print("BuffBot v0.0.4 Loaded.", debugString)

    if (BuffBot.config.buttonPosition == nil) then
        print("You can drag the BuffBot button by holding Alt.")
    else
        BuffBot.macroButton:ClearAllPoints();
        BuffBot.macroButton:SetPoint(unpack(BuffBot.config.buttonPosition));
    end
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
