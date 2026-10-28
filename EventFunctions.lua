local addonName, BuffBot = ...
local events = CreateFrame("Frame")

-- Members' auras change in bursts, so their events share one re-check
local RESCAN_DELAY = 0.2
local rescanPending = false
local function ScheduleRescan()
    if rescanPending then return end
    rescanPending = true
    C_Timer.After(RESCAN_DELAY, function()
        rescanPending = false
        BuffBot.CheckPlayerBuffs()
    end)
end

local function IsGroupUnit(unit)
    return unit:match("^party%d$") ~= nil or unit:match("^raid%d+$") ~= nil
end

-- In combat the payload can hold secrets, which add-on code can't test, so
-- check the unit before reading it. Other units' payloads are never read.
function events:UNIT_AURA(unit, info)
    if unit ~= "player" then
        if not InCombatLockdown() and IsGroupUnit(unit) then ScheduleRescan() end
        return
    end
    -- A full update triggers when people join party or player zones through instance
    local fullUpdate = info.isFullUpdate
    if not issecretvalue(fullUpdate) and fullUpdate and UnitInRaid("player") then
        BuffBot.UpdateClassBuffList()
    else
        BuffBot.CheckPlayerBuffs()
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
    BuffBot.TrackingSpellsChanged()
end

-- Fires on most power changes, so only re-tint while the button is up
function events:SPELL_UPDATE_USABLE()
    if not BuffBot.macroButton:IsShown() then return end
    BuffBot.UpdateTint()
end

-- Dying, releasing, resurrecting, and taking or leaving a flight path
function events:PLAYER_DEAD()
    BuffBot.CheckPlayerBuffs()
end

function events:PLAYER_ALIVE()
    BuffBot.CheckPlayerBuffs()
    BuffBot.UpdateTracking()
end

function events:PLAYER_UNGHOST()
    BuffBot.CheckPlayerBuffs()
    BuffBot.UpdateTracking()
end

-- Zoning, which includes leaving a battleground, where tracking isn't cast
function events:PLAYER_ENTERING_WORLD()
    BuffBot.UpdateTracking()
end

-- These fire before UnitOnTaxi changes, so re-check a moment later
function events:PLAYER_CONTROL_LOST()
    C_Timer.After(0.5, BuffBot.CheckPlayerBuffs)
end

function events:PLAYER_CONTROL_GAINED()
    C_Timer.After(0.5, BuffBot.CheckPlayerBuffs)
end

-- Weapon enchants landing or dropping, and weapon swaps
function events:UNIT_INVENTORY_CHANGED()
    BuffBot.CheckPlayerBuffs()
end

-- Poisons bought or used up
function events:BAG_UPDATE_DELAYED()
    BuffBot.CheckPlayerBuffs()
end

function events:PLAYER_REGEN_ENABLED()
    BuffBot.CheckPlayerBuffs()
    BuffBot.ResumeTracking()
end

function events:PLAYER_REGEN_DISABLED()
    BuffBot.macroButton:Hide()
end

function events:ADDON_LOADED(arg1)
    if (arg1 ~= addonName) then return end

    if BuffBotConfig == nil then
        BuffBotConfig = {}
    end
    -- Before 2.2.0, Hide Text was saved as its opposite
    if BuffBotConfig.SUGGESTION_LIST ~= nil then
        BuffBotConfig.HIDE_TEXT = not BuffBotConfig.SUGGESTION_LIST
        BuffBotConfig.SUGGESTION_LIST = nil
    end
    -- Before 2.3.0, the self blessing was a Wisdom checkbox
    if BuffBotConfig.WISDOM_SELF ~= nil then
        BuffBotConfig.PALADIN_BLESSING = BuffBotConfig.WISDOM_SELF and "Blessing of Wisdom" or "Blessing of Might"
        BuffBotConfig.WISDOM_SELF = nil
    end
    -- Before 2.5.0, buffing the rest of the raid was its own setting
    BuffBotConfig.RAID_BUFFING = nil
    -- Fill in settings added since the config was saved
    for key, value in pairs(BuffBot.GetDefaultConfig()) do
        if BuffBotConfig[key] == nil then
            BuffBotConfig[key] = value
        end
    end
    BuffBot.config = BuffBotConfig
    if BuffBotCharConfig == nil then
        BuffBotCharConfig = {}
    end
    for key, value in pairs(BuffBot.GetDefaultCharConfig()) do
        if BuffBotCharConfig[key] == nil then
            BuffBotCharConfig[key] = value
        end
    end
    BuffBot.charConfig = BuffBotCharConfig
    BuffBot.RegisterSettings()


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

events:SetScript("OnEvent", function(self, event, ...)
    self[event](self, ...)
end)

events:RegisterEvent("UNIT_AURA")

events:RegisterEvent("GROUP_ROSTER_UPDATE")
events:RegisterEvent("GROUP_LEFT")

events:RegisterEvent("SPELL_UPDATE_USABLE")
events:RegisterUnitEvent("UNIT_INVENTORY_CHANGED", "player")
events:RegisterEvent("BAG_UPDATE_DELAYED")

events:RegisterEvent("PLAYER_DEAD")
events:RegisterEvent("PLAYER_ALIVE")
events:RegisterEvent("PLAYER_UNGHOST")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_CONTROL_LOST")
events:RegisterEvent("PLAYER_CONTROL_GAINED")

events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("PLAYER_REGEN_DISABLED")

--Fired when Spellbook is populated. On login as well as when spells are learned
events:RegisterEvent("SPELLS_CHANGED")

events:RegisterEvent("ADDON_LOADED")
