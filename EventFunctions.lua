local addonName, BuffBot = ...
local events = CreateFrame("Frame")
local class = BuffBot.playerclass
local function debug() end
debug = BuffBot.debug

function events:UNIT_AURA(unit, info)
    if info.isFullUpdate then
        -- triggers when people join party or player zones through instance
        if (unit == "player") then
            if UnitInRaid("player") then
                BuffBot.UpdateClassBuffList()
            else
                BuffBot.CheckPlayerBuffs()
            end
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
end

function events:GROUP_LEFT()
    BuffBot.UpdateClassBuffList()
end

function events:SPELLS_CHANGED()
    BuffBot.UpdateClassBuffList()
end

-- Fires on most power changes, so only re-tint while the button is up
function events:SPELL_UPDATE_USABLE()
    if not BuffBot.macroButton:IsShown() then return end
    BuffBot.UpdateTint()
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
        BuffBotConfig = {}
    end
    -- Fill in settings added since the config was saved
    for key, value in pairs(BuffBot.GetDefaultConfig()) do
        if BuffBotConfig[key] == nil then
            BuffBotConfig[key] = value
        end
    end
    BuffBot.config = BuffBotConfig


    local debugString = ""
    if BuffBot.config.DEBUG_MODE then
        debugString = "- DEBUG MODE ON"
    end
    local version = C_AddOns.GetAddOnMetadata(addonName, "Version")
    print("BuffBot|cff00ccff v" .. version .. "|r Loaded. /bb", debugString)

    if (BuffBot.config.buttonPosition == nil) then
        print("You can drag the BuffBot button by holding Alt.")
    else
        BuffBot.RestoreMacroButtonPosition()
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

events:RegisterEvent("SPELL_UPDATE_USABLE")

events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("PLAYER_REGEN_DISABLED")

--Fired when Spellbook is populated. On login as well as when spells are learned
events:RegisterEvent("SPELLS_CHANGED")

events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGOUT")
