local _, BuffBot = ...

local panel = CreateFrame("Frame")
panel.name = "BuffBot"
InterfaceOptions_AddCategory(panel)

function BuffBot.GetDefaultConfig() 
    local defaultConfig = {}
    defaultConfig.HIDE_ICON = false
    defaultConfig.SUGGESTION_LIST = true

    defaultConfig.BLOODRAGE = false
    defaultConfig.WISDOM_SELF = false
    defaultConfig.STRICT_ARMOR = false
    defaultConfig.IGNORE_THORNS = false
    defaultConfig.IGNORE_DAMPEN = false

    return defaultConfig
end


local function PaintSettingsFrame()

    -- TOP AREA 
        local t = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        t:SetText(panel.name .. " Settings")
        t:SetPoint("TOPLEFT", panel, 15, -15)

       

        local btHideIcon = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        btHideIcon:SetPoint("TOPLEFT", panel, 15, -60)
        btHideIcon.text = btHideIcon:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        btHideIcon.text:SetPoint("LEFT", btHideIcon, "RIGHT", 0, 1)
        btHideIcon.text:SetText("Hide Icon [NYI]")
        btHideIcon:SetChecked(BuffBot.config.HIDE_ICON)
        btHideIcon:SetScript("OnClick", function()
            if btHideIcon:GetChecked() then
            else
            end
        end)

        local btnSuggestionList  = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        btnSuggestionList:SetPoint("TOPLEFT", btHideIcon, 120, 0)
        btnSuggestionList.text = btnSuggestionList:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        btnSuggestionList.text:SetPoint("LEFT", btnSuggestionList , "RIGHT", 0, 1)
        btnSuggestionList.text:SetText("Show Suggestion List")
        btnSuggestionList:SetChecked(BuffBot.config.SUGGESTION_LIST)
        btnSuggestionList:SetScript("OnClick", function()
            BuffBot.debug("Suggestion List - ", btnSuggestionList:GetChecked())
            BuffBot.config.SUGGESTION_LIST = btnSuggestionList:GetChecked()
            BuffBot.UpdateSuggestionList()
        end)

        -- CLASS SETTINGS --
        -- Gap between classes : -40
        -- Gap within classes: -25
		local classSettings = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        classSettings:SetText("Class Settings")
        classSettings:SetPoint("TOPLEFT", panel, 15, -115)

        local btnStrictArmor = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        btnStrictArmor:SetPoint("TOPLEFT", classSettings, 15, -25)
        btnStrictArmor.text = btnStrictArmor:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        btnStrictArmor.text:SetPoint("LEFT", btnStrictArmor, "RIGHT", 0, 1)
        btnStrictArmor.text:SetText("Strict Mage Armors [NYI]")
        btnStrictArmor:SetChecked(BuffBot.config.STRICT_ARMOR)
        btnStrictArmor:SetScript("OnClick", function()
            local icon = LibStub("LibDBIcon-1.0")
            if btnStrictArmor:GetChecked() then
            else
            end
        end)

        local btnIgnoreDampen = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        btnIgnoreDampen:SetPoint("TOPLEFT", btnStrictArmor, 0, -25)
        btnIgnoreDampen.text = btnIgnoreDampen:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        btnIgnoreDampen.text:SetPoint("LEFT", btnIgnoreDampen, "RIGHT", 0, 1)
        btnIgnoreDampen.text:SetText("Skip Dampen Magic [NYI]")
        btnIgnoreDampen:SetChecked(BuffBot.config.IGNORE_DAMPEN)
        btnIgnoreDampen:SetScript("OnClick", function()
            local icon = LibStub("LibDBIcon-1.0")
            if btnIgnoreDampen:GetChecked() then
            else
            end
        end)

		local btBloodrage = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        btBloodrage:SetPoint("TOPLEFT", btnIgnoreDampen, 0, -40)

        btBloodrage.text = btBloodrage:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        btBloodrage.text:SetPoint("LEFT", btBloodrage, "RIGHT", 0, 1)
        btBloodrage.text:SetText("Include Bloodrage [NYI]")
        btBloodrage:SetChecked(BuffBot.config.BLOODRAGE)
        btBloodrage:SetScript("OnClick", function()
            if btBloodrage:GetChecked() then
            else
            end
        end)
		
        local btnBlessingOfWisdom  = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        btnBlessingOfWisdom :SetPoint("TOPLEFT", btBloodrage, 0, -40)

        btnBlessingOfWisdom .text = btnBlessingOfWisdom :CreateFontString(nil, "OVERLAY", "GameFontNormal")
        btnBlessingOfWisdom .text:SetPoint("LEFT", btnBlessingOfWisdom , "RIGHT", 0, 1)
        btnBlessingOfWisdom .text:SetText("Selfbuff Blessing of Wisdom")
        btnBlessingOfWisdom :SetChecked(BuffBot.config.WISDOM_SELF)
        btnBlessingOfWisdom :SetScript("OnClick", function()
            BuffBot.debug("Wisdom changed - ", btnBlessingOfWisdom:GetChecked())
            BuffBot.config.WISDOM_SELF = btnBlessingOfWisdom:GetChecked()
            BuffBot.UpdateClassBuffList()
        end)
        
        local btnIgnoreThorns = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        btnIgnoreThorns:SetPoint("TOPLEFT", btnBlessingOfWisdom, 0, -40)
        btnIgnoreThorns.text = btnIgnoreThorns:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        btnIgnoreThorns.text:SetPoint("LEFT", btnIgnoreThorns, "RIGHT", 0, 1)
        btnIgnoreThorns.text:SetText("Skip Thorns [NYI]")
        btnIgnoreThorns:SetChecked(BuffBot.config.IGNORE_THORNS)
        btnIgnoreThorns:SetScript("OnClick", function()
            BuffBot.debug("Thorns changed - ", btnBlessingOfWisdom:GetChecked())
            BuffBot.config.IGNORE_THORNS= btnBlessingOfWisdom:GetChecked()
            BuffBot.UpdateClassBuffList()
        end)

        -- FOOTER -- 
         local t = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        t:SetText("Addon Author: Smiil-LivingFlame  -  Discord: smiil")
        t:SetPoint("BOTTOMLEFT", panel, 25, 30)
end

panel:SetScript("OnShow", function ()
    PaintSettingsFrame()
end)