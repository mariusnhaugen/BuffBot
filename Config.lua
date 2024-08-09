local _, BuffBot = ...

local configPanel = CreateFrame("Frame")
configPanel.name = "BuffBot"
InterfaceOptions_AddCategory(configPanel)

function BuffBot.GetDefaultConfig()
    local defaultConfig = {}
    defaultConfig.HIDE_ICON = false
    defaultConfig.SUGGESTION_LIST = true
    defaultConfig.DEBUG_MODE = false

    defaultConfig.BLOODRAGE = false
    defaultConfig.WISDOM_SELF = false
    defaultConfig.STRICT_ARMOR = false
    defaultConfig.IGNORE_THORNS = false
    defaultConfig.IGNORE_DAMPEN = false
    defaultConfig.CHEETAH_REMINDER = true

    return defaultConfig
end

local function PaintSettingsFrame()
    local function createCheckbox(label, description, onClick)
        local check = CreateFrame("CheckButton", "BuffBotCheckbox" .. label, configPanel,
            "InterfaceOptionsCheckButtonTemplate")
        check:SetScript("OnClick", function(self)
            local tick = self:GetChecked()
            onClick(self, tick and true or false)
        end)
        check.label = _G[check:GetName() .. "Text"]
        check.label:SetText(label)
        check.tooltipText = label
        check.tooltipRequirement = description
        return check
    end

    -- ############### Title
    local title = configPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", configPanel, 15, -15)
    title:SetText(configPanel.name .. " Settings")

    -- ############### Description

    local slashCommandDescription = configPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    slashCommandDescription:SetPoint("TOPLEFT", title, 10, -25)
    slashCommandDescription:SetText("/bb, /buffbot to open this page.")

    local mainDescription = configPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    mainDescription:SetPoint("TOPLEFT", slashCommandDescription, 0, -20)
    mainDescription:SetText(
        "For best experience, Set a keybind in Blizzard Keybindings>AddOns to configure a spammable macro button")


    -- ############### Top Checkboxes
    -- local checkboxHideIcon = createCheckbox(
    --     "Hide Icon [NYI]",
    --     "Hides Icon for text only/stealth mode buffing",
    --     function(_, checkboxValue)
    --         BuffBot.debug("Suggestion List - ", checkboxValue)
    --         BuffBot.config.HIDE_ICON= checkboxValue
    --         BuffBot.UpdateSuggestionList()
    --     end)
    -- checkboxHideIcon:SetPoint("TOPLEFT", slashCommandDescription, 0, -20)
    -- checkboxHideIcon:SetChecked(BuffBot.config.HIDE_ICON)
    -- checkboxHideIcon:Disable()

    local checkboxSuggestionList = createCheckbox(
        "Show Suggestion List",
        "Shows list of the buttons next suggested casts.",
        function(_, checkboxValue)
            BuffBot.debug("Suggestion List - ", checkboxValue)
            BuffBot.config.SUGGESTION_LIST = checkboxValue
            BuffBot.UpdateSuggestionList()
        end)
    checkboxSuggestionList:SetPoint("TOPLEFT", slashCommandDescription, 0, -50)
    -- checkboxSuggestionList:SetPoint("TOPLEFT", checkboxHideIcon, 120, 0) --### when hideicon is back
    checkboxSuggestionList:SetChecked(BuffBot.config.SUGGESTION_LIST)

    local buttonResetPosition = CreateFrame("Button", nil, configPanel, "UIPanelButtonTemplate")
    buttonResetPosition:SetPoint("TOPLEFT", checkboxSuggestionList, 320, 0)
    buttonResetPosition:SetText("Reset Button Position")
    buttonResetPosition:SetWidth(140)
    buttonResetPosition:SetHeight(28)
    buttonResetPosition:SetScript("OnClick", function()
        BuffBot.debug("Macro button position reset ")
        BuffBot.SetMacroButtonDefaultPosition()
    end)
    buttonResetPosition.tooltipText = "Resets Main Button Position"
    buttonResetPosition.newbieText = "You can move the button by holding Alt and dragging."


    -- ############### CLASS SETTINGS
    -- Gap between classes : -40
    -- Gap within classes: -25
    local classSettings = configPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    classSettings:SetText("Class Settings")
    classSettings:SetPoint("TOPLEFT", configPanel, 15, -135)

    local buttonStrictArmor = createCheckbox(
        "Strict Mage Armors",
        "Disallow any armor being valid when recommending a Mage armor buff. \n \n Open World:  Molten Armor > Ice Armor \n In Raid:         Molten Armor > Mage Armor",
        function(_, checkboxValue)
            BuffBot.debug("Dampen changed - ", checkboxValue)
            BuffBot.config.STRICT_ARMOR = checkboxValue
            BuffBot.UpdateClassBuffList()
        end)
    buttonStrictArmor:SetPoint("TOPLEFT", classSettings, 15, -25)
    buttonStrictArmor:SetChecked(BuffBot.config.STRICT_ARMOR)

    local buttonIgnoreDampen = createCheckbox(
        "Skip Dampen Magic",
        "Skip recommending Dampen Magic.",
        function(_, checkboxValue)
            BuffBot.debug("Dampen changed - ", checkboxValue)
            BuffBot.config.IGNORE_DAMPEN = checkboxValue
            BuffBot.UpdateClassBuffList()
        end)
    buttonIgnoreDampen:SetPoint("TOPLEFT", buttonStrictArmor, 0, -25)
    buttonIgnoreDampen:SetChecked(BuffBot.config.IGNORE_DAMPEN)


    local buttonBloodrage = createCheckbox(
        "Include Bloodrage (Buggy)",
        "Include Bloodrage if the warrior is missing rage to cast Battle Shout \n\n|cFFFF0000Absolutely disintegrates if Battle Shout drops off with Bloodrage on cooldown.|r",
        function(_, checkboxValue)
            BuffBot.debug("Bloodrage - ", checkboxValue)
            BuffBot.config.BLOODRAGE = checkboxValue
            BuffBot.UpdateClassBuffList()
        end)
    buttonBloodrage:SetPoint("TOPLEFT", buttonIgnoreDampen, 0, -40)
    buttonBloodrage:SetChecked(BuffBot.config.BLOODRAGE)


    local buttonBlessingOfWisdom = createCheckbox(
        "Recommend Blessing of Wisdom",
        "Cast Blessing of Wisdom over Blessing of Might.",
        function(_, checkBoxValue)
            BuffBot.debug("Wisdom changed - ", checkBoxValue)
            BuffBot.config.WISDOM_SELF = checkBoxValue
            BuffBot.UpdateClassBuffList()
        end)
    buttonBlessingOfWisdom:SetPoint("TOPLEFT", buttonBloodrage, 0, -40)
    buttonBlessingOfWisdom:SetChecked(BuffBot.config.WISDOM_SELF)


    local buttonIgnoreThorns = createCheckbox(
        "Skip Thorns",
        "Skip recommending Thorns.",
        function(_, checkBoxValue)
            BuffBot.debug("Thorns changed - ", checkBoxValue)
            BuffBot.config.IGNORE_THORNS = checkBoxValue
            BuffBot.UpdateClassBuffList()
        end)
    buttonIgnoreThorns:SetPoint("TOPLEFT", buttonBlessingOfWisdom, 0, -40)
    buttonIgnoreThorns:SetChecked(BuffBot.config.IGNORE_THORNS)

    local buttonCheetahReminder = createCheckbox(
        "Reminder to leave Cheetah",
        "Shows Aspect of the Hawk if you are in Aspect of the Cheetah/Pack",
        function(_, checkboxValue)
            BuffBot.debug("Cheetah reminder changed - ", checkboxValue)
            BuffBot.config.CHEETAH_REMINDER = checkboxValue
            BuffBot.UpdateClassBuffList()
        end)
    buttonCheetahReminder:SetPoint("TOPLEFT", buttonIgnoreThorns, 0, -40)
    buttonCheetahReminder:SetChecked(BuffBot.config.CHEETAH_REMINDER)

    -- FOOTER --
    local t = configPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    t:SetText("Addon Author: Smiil-LivingFlame  -  Discord: smiil")
    t:SetPoint("BOTTOMLEFT", configPanel, 25, 30)
end

configPanel:SetScript("OnShow", function()
    PaintSettingsFrame()
    configPanel:SetScript("OnShow", nil)
end)
