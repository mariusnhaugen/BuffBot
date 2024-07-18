local _, BuffBot = ...
local RegEvent = BuffBot.regevent


local panel = CreateFrame("Frame")
panel.name = "BuffBot"
InterfaceOptions_AddCategory(panel)
-- local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
-- BuffBot.settingcategory = category
-- Settings.RegisterAddOnCategory(category)

function PaintSettingsFrame()
        local t = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        t:SetText(panel.name .. " Settings")
        t:SetPoint("TOPLEFT", panel, 15, -15)

        local t = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        t:SetText("Addon Author: Smiil-LivingFlame  -  Discord: smiil")
        t:SetPoint("TOPLEFT", panel, 15, -50)

		-- Tick box
        local btHideIcon = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        btHideIcon:SetPoint("TOPLEFT", panel, 15, -80)

        btHideIcon.text = btHideIcon:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        btHideIcon.text:SetPoint("LEFT", btHideIcon, "RIGHT", 0, 1)
        btHideIcon.text:SetText("Hide Icon")
        btHideIcon:SetChecked(false)
        btHideIcon:SetScript("OnClick", function()
            if btHideIcon:GetChecked() then
            else
            end
        end)

		local classSettings = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        classSettings:SetText("Class Settings")
        classSettings:SetPoint("TOPLEFT", panel, 15, -135)

        local btStrictArmor = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        btStrictArmor:SetPoint("TOPLEFT", classSettings, 15, -25)

        btStrictArmor.text = btStrictArmor:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        btStrictArmor.text:SetPoint("LEFT", btStrictArmor, "RIGHT", 0, 1)
        btStrictArmor.text:SetText("Strict Mage Armors")
        btStrictArmor:SetChecked(false)
        btStrictArmor:SetScript("OnClick", function()
            local icon = LibStub("LibDBIcon-1.0")
            if btStrictArmor:GetChecked() then
            else
            end
        end)

		local btBloodrage = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        btBloodrage:SetPoint("TOPLEFT", btStrictArmor, 0, -35)

        btBloodrage.text = btBloodrage:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        btBloodrage.text:SetPoint("LEFT", btBloodrage, "RIGHT", 0, 1)
        btBloodrage.text:SetText("Include Bloodrage")
        btBloodrage:SetChecked(false)
        btBloodrage:SetScript("OnClick", function()
            if btBloodrage:GetChecked() then
            else
            end
        end)
end

PaintSettingsFrame()

