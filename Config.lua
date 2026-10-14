local _, BuffBot = ...

local configPanel = CreateFrame("Frame")
configPanel.name = "BuffBot"

local category = Settings.RegisterCanvasLayoutCategory(configPanel,"BuffBot")
Settings.RegisterAddOnCategory(category)

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
    defaultConfig.SUGGESTION_LIST = true
    defaultConfig.DEBUG_MODE = false

    defaultConfig.BLOODRAGE = false
    defaultConfig.WISDOM_SELF = false
    defaultConfig.STRICT_ARMOR = false
    defaultConfig.IGNORE_THORNS = false
    defaultConfig.IGNORE_DAMPEN = false
    defaultConfig.CHEETAH_REMINDER = true
    defaultConfig.SHAMAN_IMBUE = "Rockbiter Weapon"

    return defaultConfig
end

local function PaintSettingsFrame()
    -- The templates don't show tooltipText on hover on Forever
    local function addTooltip(frame, title, text)
        frame:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(title, 1, 1, 1)
            GameTooltip:AddLine(text, nil, nil, nil, true)
            GameTooltip:Show()
        end)
        frame:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end

    local function createCheckbox(label, description, onClick)
        local check = CreateFrame("CheckButton", "BuffBotCheckbox" .. label, configPanel,
            "InterfaceOptionsCheckButtonTemplate")
        check:SetScript("OnClick", function(self)
            local tick = self:GetChecked()
            onClick(self, tick and true or false)
        end)
        check.label = _G[check:GetName() .. "Text"]
        check.label:SetText(label)
        addTooltip(check, label, description)
        return check
    end

    -- A labelled dropdown that sets config[setting] to one of options' values
    local function createDropdown(name, labelText, setting, options)
        local label = configPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        label:SetText(labelText)
        local dropdown = CreateFrame("DropdownButton", "BuffBotDropdown" .. name, configPanel,
            "WowStyle1DropdownTemplate")
        dropdown:SetWidth(180)
        dropdown:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -5)
        dropdown:SetupMenu(function(_, rootDescription)
            for _, option in ipairs(options) do
                rootDescription:CreateRadio(option.text,
                    function() return BuffBot.config[setting] == option.value end,
                    function()
                        BuffBot.debug(name, " changed - ", option.value)
                        BuffBot.config[setting] = option.value
                        BuffBot.UpdateClassBuffList()
                    end)
            end
        end)
        return label
    end

    -- ############### Title
    local title = configPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", configPanel, 15, -15)
    title:SetText(configPanel.name .. " Settings")

    -- ############### Description


    local mainDescription = configPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    mainDescription:SetPoint("TOPLEFT", title, 10, -30)
    mainDescription:SetText(
        "For best experience, Set a keybind in Blizzard Keybindings>AddOns to configure a spammable macro button.")
    
    local slashCommandDescription = configPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    slashCommandDescription:SetPoint("TOPLEFT", mainDescription, 0, -20)
    slashCommandDescription:SetText("/bb, /buffbot to open this page. Alt+Drag to move the main button.")

    -- ############### Top Checkboxes
    local checkboxHideIcon = createCheckbox(
        "Hide Icon",
        "Hides the button icon for text-only buffing. The keybind and the text still work.",
        function(_, checkboxValue)
            BuffBot.debug("Hide Icon - ", checkboxValue)
            BuffBot.config.HIDE_ICON = checkboxValue
            BuffBot.UpdateIconVisibility()
        end)
    checkboxHideIcon:SetPoint("TOPLEFT", mainDescription, 0, -50)
    checkboxHideIcon:SetChecked(BuffBot.config.HIDE_ICON)

    -- Saved as SUGGESTION_LIST, so the checkbox is its opposite
    local checkboxHideText = createCheckbox(
        "Hide Text",
        "Hides the list of upcoming buffs under the button.",
        function(_, checkboxValue)
            BuffBot.debug("Hide Text - ", checkboxValue)
            BuffBot.config.SUGGESTION_LIST = not checkboxValue
            BuffBot.UpdateSuggestionList()
        end)
    checkboxHideText:SetPoint("TOPLEFT", checkboxHideIcon, 120, 0)
    checkboxHideText:SetChecked(not BuffBot.config.SUGGESTION_LIST)

    local buttonResetPosition = CreateFrame("Button", nil, configPanel, "UIPanelButtonTemplate")
    buttonResetPosition:SetPoint("TOPLEFT", checkboxHideIcon, 320, 0)
    buttonResetPosition:SetText("Reset Button Position")
    buttonResetPosition:SetWidth(140)
    buttonResetPosition:SetHeight(28)
    buttonResetPosition:SetScript("OnClick", function()
        -- Moving the secure button is blocked in combat
        if InCombatLockdown() then
            print("BuffBot: can't move the button in combat.")
            return
        end
        BuffBot.debug("Macro button position reset ")
        BuffBot.SetMacroButtonDefaultPosition()
    end)
    addTooltip(buttonResetPosition, "Resets Main Button Position",
        "You can move the button by holding Alt and dragging.")


    -- ############### CLASS SETTINGS
    -- Gap between classes : -40
    -- Gap within classes: -25
    local classSettings = configPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    classSettings:SetText("Class Settings")
    classSettings:SetPoint("TOPLEFT", configPanel, 15, -135)

    local buttonStrictArmor = createCheckbox(
        "Strict Mage Armors",
        "Disallow any armor being valid when recommending a Mage armor buff. \n \n Open World:  Ice Armor \n In Raid:         Mage Armor",
        function(_, checkboxValue)
            BuffBot.debug("Strict Armor changed - ", checkboxValue)
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
        "Always try Bloodrage out of combat",
        "Cast Bloodrage before Battle Shout out of combat. \n\nCan cause error spam while Bloodrage is on cooldown.",
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

    -- Weapon enchants, by the client's names
    local imbues = {}
    for _, imbue in ipairs({ "Rockbiter Weapon", "Flametongue Weapon", "Frostbrand Weapon", "Windfury Weapon" }) do
        table.insert(imbues, { text = BuffBot.SpellName(imbue), value = imbue })
    end
    local imbueLabel = createDropdown("ShamanImbue", "Shaman weapon imbue:", "SHAMAN_IMBUE", imbues)
    imbueLabel:SetPoint("TOPLEFT", buttonCheetahReminder, 0, -40)

    -- FOOTER --
    local t = configPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    t:SetText("Addon Author: Smiil  -  Discord: smiil")
    t:SetPoint("BOTTOMLEFT", configPanel, 25, 30)
end

configPanel:SetScript("OnShow", function()
    PaintSettingsFrame()
    configPanel:SetScript("OnShow", nil)
end)
