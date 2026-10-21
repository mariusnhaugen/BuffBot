local _, BuffBot = ...

local category

SLASH_BUFFBOTSETTINGS1 = "/bb";
SLASH_BUFFBOTSETTINGS2 = "/buffbot";
SlashCmdList.BUFFBOTSETTINGS = function(arg)
    if arg == "" then
        Settings.OpenToCategory(category:GetID())
        return
    end

    if arg == "buffs" then
        local buffs = BuffBot.classBuffList or {}
        if #buffs == 0 then
            print("BuffBot buffs: none")
        else
            print("BuffBot buffs: " .. table.concat(buffs, ", "))
        end
        return
    end

    if arg == "debug" then
        BuffBot.config.DEBUG_MODE = not BuffBot.config.DEBUG_MODE
        print("BuffBot Debug Mode -", BuffBot.config.DEBUG_MODE)
        return
    end
end

function BuffBot.GetDefaultConfig()
    local defaultConfig = {}
    defaultConfig.HIDE_ICON = false
    defaultConfig.HIDE_TEXT = false
    defaultConfig.DEBUG_MODE = false

    defaultConfig.BLOODRAGE = false
    defaultConfig.WISDOM_SELF = false
    defaultConfig.RIGHTEOUS_FURY = false
    defaultConfig.STRICT_ARMOR = false
    defaultConfig.IGNORE_THORNS = false
    defaultConfig.IGNORE_DAMPEN = false
    defaultConfig.CHEETAH_REMINDER = true
    defaultConfig.SHAMAN_IMBUE = "Rockbiter Weapon"
    defaultConfig.ROGUE_POISON_MAINHAND = "Instant Poison"
    defaultConfig.ROGUE_POISON_OFFHAND = "Instant Poison"
    defaultConfig.TRACK_TREASURE = true

    return defaultConfig
end

-- Saved per character, in BuffBotCharConfig
function BuffBot.GetDefaultCharConfig()
    -- "" until the player picks a tracker, so the default follows what the
    -- character knows
    return { TRACKER = "" }
end

-- The settings page, built by the Settings API. Each setting reads and writes
-- BuffBotConfig directly, so it runs on ADDON_LOADED once the defaults are in.
function BuffBot.RegisterSettings()
    local layout
    category, layout = Settings.RegisterVerticalLayoutCategory("BuffBot")
    local defaults = BuffBot.GetDefaultConfig()

    -- tbl and default are for settings outside BuffBot.config
    local function addSetting(key, varType, label, onChange, tbl, default)
        if default == nil then default = defaults[key] end
        local setting = Settings.RegisterAddOnSetting(category, "BuffBot_" .. key, key, tbl or BuffBot.config,
            varType, label, default)
        setting:SetValueChangedCallback(function(_, value)
            BuffBot.debug(label, " changed - ", value)
            onChange()
        end)
        return setting
    end

    local function addCheckbox(key, label, tooltip, onChange)
        local setting = addSetting(key, Settings.VarType.Boolean, label, onChange or BuffBot.UpdateClassBuffList)
        Settings.CreateCheckbox(category, setting, tooltip)
    end

    -- options: { value, English name } pairs; nameOf gives the client's name
    local function addDropdown(key, label, tooltip, values, nameOf)
        local setting = addSetting(key, Settings.VarType.String, label, BuffBot.UpdateClassBuffList)
        local function options()
            local container = Settings.CreateControlTextContainer()
            for _, value in ipairs(values) do
                container:Add(value, nameOf(value))
            end
            return container:GetData()
        end
        Settings.CreateDropdown(category, setting, options, tooltip)
    end

    addCheckbox("HIDE_ICON", "Hide Icon",
        "Hides the button icon for text-only buffing. The keybind (Key Bindings > AddOns) and the text still work.",
        BuffBot.UpdateIconVisibility)
    addCheckbox("HIDE_TEXT", "Hide Text", "Hides the list of upcoming buffs under the button.",
        BuffBot.UpdateSuggestionList)

    layout:AddInitializer(CreateSettingsButtonInitializer("Button Position", "Reset Button Position", function()
        -- Moving the secure button is blocked in combat
        if InCombatLockdown() then
            print("BuffBot: can't move the button in combat.")
            return
        end
        BuffBot.debug("Macro button position reset ")
        BuffBot.SetMacroButtonDefaultPosition()
    end, "Moves the button back to the middle of the screen. You can move it by holding Alt and dragging.", true))

    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Tracking"))

    -- Picking a tracker, or Default, switches to it now; Off turns nothing off
    local tracker = addSetting("TRACKER", Settings.VarType.String, "Auto tracking", function()
        local value = BuffBot.charConfig.TRACKER
        if value == "Off" then return end
        BuffBot.UpdateTracking(value ~= "" and value or BuffBot.DefaultTracker())
    end, BuffBot.charConfig, BuffBot.GetDefaultCharConfig().TRACKER)
    local function trackerOptions()
        local container = Settings.CreateControlTextContainer()
        local default = BuffBot.DefaultTracker()
        container:Add("", "Default (" .. (default and BuffBot.SpellName(default) or "Off") .. ")")
        for _, key in ipairs(BuffBot.Trackers) do
            if BuffBot.KnowsTracker(key) then container:Add(key, BuffBot.SpellName(key)) end
        end
        container:Add("Off", "Off")
        return container:GetData()
    end
    Settings.CreateDropdown(category, tracker, trackerOptions,
        "Turned back on after you die or log in. Default will pick up when you learn a profession. Prio list: Find Minerals > Herbs > Track Beasts. Saved per character. Triggers a global cooldown.")
    addCheckbox("TRACK_TREASURE", "Auto Find Treasure",
        "For Dwarves: Automatically cast Find Treasure. Triggers a 2nd global cooldown.",
        function() BuffBot.UpdateTracking() end)

    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Class Settings"))

    addCheckbox("STRICT_ARMOR", "Strict Mage Armors",
        "Disallow any armor being valid when recommending a Mage armor buff. \n \n Open World:  Ice Armor \n In Raid:         Mage Armor")
    addCheckbox("IGNORE_DAMPEN", "Skip Dampen Magic", "Skip recommending Dampen Magic.")
    addCheckbox("BLOODRAGE", "Always try Bloodrage out of combat",
        "Cast Bloodrage before Battle Shout out of combat. \n\nCan cause error spam while Bloodrage is on cooldown.")
    addCheckbox("WISDOM_SELF", "Recommend Blessing of Wisdom", "Cast Blessing of Wisdom over Blessing of Might.")
    addCheckbox("RIGHTEOUS_FURY", "Recommend Righteous Fury", "Cast Righteous Fury, for tanking.")
    addCheckbox("IGNORE_THORNS", "Skip Thorns", "Skip recommending Thorns.")
    addCheckbox("CHEETAH_REMINDER", "Reminder to leave Cheetah",
        "Shows Aspect of the Hawk if you are in Aspect of the Cheetah/Pack")

    addDropdown("SHAMAN_IMBUE", "Shaman weapon imbue", "The imbue the button puts on your main hand.",
        { "Rockbiter Weapon", "Flametongue Weapon", "Frostbrand Weapon", "Windfury Weapon" }, BuffBot.SpellName)
    addDropdown("ROGUE_POISON_MAINHAND", "Rogue main hand poison",
        "The poison for your main hand. Another poison is used if you run out.", BuffBot.PoisonTypes, BuffBot.PoisonName)
    addDropdown("ROGUE_POISON_OFFHAND", "Rogue off hand poison",
        "The poison for your off hand. Another poison is used if you run out.", BuffBot.PoisonTypes, BuffBot.PoisonName)

    Settings.RegisterAddOnCategory(category)
end
