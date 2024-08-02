local _, BuffBot = ...
local macroButton;

local LEFTBUTTON = 'LeftButton';
local MIDDLEBUTTON = 'MiddleButton';

BuffBot.futureBuffStrings = {}

-- Define blizzard Keybind
_G["BINDING_NAME_" .. "CLICK BUFFBOT_MacroButton:LeftButton"] = "BuffBot Cast"

--################### Public Functions ##########################
function BuffBot.UpdateMacro(spellName, unit)
    if InCombatLockdown() then return end
    local texture = GetSpellTexture(spellName)
    if texture then
        macroButton:SetNormalTexture(texture)
    end
    macroButton:SetAttribute("macrotext1", "/cast [target=" .. unit .. "]" .. spellName) -- text for macro on left click
    macroButton:Show()
end

function BuffBot.SetMacroButtonDefaultPosition()
    macroButton:ClearAllPoints();
    macroButton:SetPoint("CENTER", UIParent, "CENTER", 100, 0);
end

--#################### UI Functions ##########################
local function stopMovingMacroButton()
    macroButton:SetScript('OnMouseUp', nil);
    macroButton:SetMovable(false);
    macroButton:StopMovingOrSizing();
    if (macroButton.draggableOverlay ~= nil) then
        macroButton.draggableOverlay:Hide()
    end
    BuffBot.config.buttonPosition = { macroButton:GetPoint() };
end

local function moveMacroButton()
    macroButton:SetScript('OnMouseUp', stopMovingMacroButton);
    macroButton:SetMovable(true);
    macroButton:StartMoving();
end

macroButton = CreateFrame("Button", "BUFFBOT_MacroButton", UIParent, "SecureActionButtonTemplate")
macroButton:SetAttribute("type1", "macro") -- left click triggers macro
macroButton:SetSize(48, 48)
macroButton:SetClampedToScreen(true);
BuffBot.SetMacroButtonDefaultPosition()

macroButton:SetScript('OnMouseDown', function(_, button)
    if (button == LEFTBUTTON and IsAltKeyDown()) then
        if (macroButton.draggableOverlay == nil) then
            macroButton.draggableOverlay = macroButton:CreateTexture("t", "OVERLAY")
            macroButton.draggableOverlay:SetAllPoints()
            macroButton.draggableOverlay:SetColorTexture(0, 0.7, 0.7, 0.5)
        else
            macroButton.draggableOverlay:Show()
        end
        moveMacroButton()
    end
end)


BuffBot.suggestionList = {}
local function FilterSuggestionList()
    local filteredTable = {}
    for i = 1, #BuffBot.futureBuffStrings, 1 do
        if not BuffBot.UnitHasAssignedBuff("player", BuffBot.futureBuffStrings[i]) then
            table.insert(filteredTable, BuffBot.futureBuffStrings[i])
        end
    end
    BuffBot.futureBuffStrings = filteredTable
end

function BuffBot.UpdateSuggestionList()
    if #BuffBot.suggestionList then
        for i = 1, #BuffBot.suggestionList, 1 do
            BuffBot.suggestionList[i]:SetText("")
            BuffBot.suggestionList[i]:Hide()
        end
    end

    if not BuffBot.config.SUGGESTION_LIST then return end
    local classBuffs = BuffBot.classBuffList
    if #classBuffs > 0 then
        local nextIndex = BuffBot.IndexOf(BuffBot.FindNextBuffInList(), classBuffs)
        BuffBot.futureBuffStrings = { unpack(classBuffs, nextIndex, #classBuffs) }

        FilterSuggestionList()

        for i = 1, #BuffBot.futureBuffStrings, 1 do
            if i == 6 then break end
            local offset = -35 + (i * -15)
            if (not BuffBot.suggestionList[i]) and (i <= 5) then
                BuffBot.suggestionList[i] = macroButton:CreateFontString(nil, "OVERLAY", "GameTooltipText")
                BuffBot.suggestionList[i]:SetPoint("TOPLEFT", macroButton, 0, offset)
            end
            BuffBot.suggestionList[i]:SetText(BuffBot.futureBuffStrings[i])
            BuffBot.suggestionList[i]:Show()
        end
    end
end

--- Namespacing  ---
BuffBot.macroButton = macroButton;
