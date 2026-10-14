local _, BuffBot = ...
local macroButton;

local LEFTBUTTON = 'LeftButton';

-- Define blizzard Keybind
_G["BINDING_NAME_" .. "CLICK BUFFBOT_MacroButton:LeftButton"] = "BuffBot Cast"

--################### Public Functions ##########################
-- Blue when out of mana or rage, like the action bars. Not for a firstSpell
-- macro, which makes its own rage.
function BuffBot.UpdateTint()
    local icon = macroButton:GetNormalTexture()
    if not icon then return end
    local noPower = false
    if macroButton.spell then
        noPower = select(2, C_Spell.IsSpellUsable(BuffBot.SpellName(macroButton.spell)))
    end
    if noPower and not macroButton.hasFirstSpell then
        icon:SetVertexColor(0.5, 0.5, 1.0)
    else
        icon:SetVertexColor(1.0, 1.0, 1.0)
    end
end

-- Hide Icon leaves the suggestion list, which is attached to the button, and
-- the keybind. The mouse can't be toggled on a secure button in combat, so
-- that part waits for the next update out of combat.
function BuffBot.UpdateIconVisibility()
    local hidden = BuffBot.config.HIDE_ICON
    local icon = macroButton:GetNormalTexture()
    if icon then
        icon:SetAlpha(hidden and 0 or 1)
    end
    if not InCombatLockdown() then
        macroButton:EnableMouse(not hidden)
    end
end

local function ShowMacro(texture, macro)
    if texture then
        macroButton:SetNormalTexture(texture)
    end
    BuffBot.UpdateTint()
    BuffBot.UpdateIconVisibility()
    macroButton:SetAttribute("macrotext1", macro) -- text for macro on left click
    macroButton:Show()
end

-- firstSpell, if given, is tried first on each press out of combat
function BuffBot.UpdateMacro(spellName, unit, firstSpell)
    if InCombatLockdown() then return end
    macroButton.spell = spellName
    macroButton.hasFirstSpell = firstSpell ~= nil
    local macro = "/cast [target=" .. unit .. "]" .. BuffBot.SpellName(spellName)
    if firstSpell then
        macro = "/cast [nocombat] " .. BuffBot.SpellName(firstSpell) .. "\n" .. macro
    end
    ShowMacro(C_Spell.GetSpellTexture(BuffBot.SpellName(spellName)), macro)
end

-- Uses an item on the weapon in invSlot (16 main hand, 17 off hand). By item
-- ID, so the macro works in any client language.
function BuffBot.UpdateItemMacro(itemID, invSlot)
    if InCombatLockdown() then return end
    macroButton.spell = nil
    macroButton.hasFirstSpell = false
    ShowMacro(C_Item.GetItemIconByID(itemID), "/use item:" .. itemID .. "\n/use " .. invSlot)
end

function BuffBot.SetMacroButtonDefaultPosition()
    macroButton:ClearAllPoints();
    macroButton:SetPoint("CENTER", UIParent, "CENTER", 100, 0);
end

function BuffBot.RestoreMacroButtonPosition()
    local saved = BuffBot.config.buttonPosition
    -- Older versions saved the GetPoint() list, including the anchor frame
    local point = saved.point or saved[1]
    if not point then
        BuffBot.config.buttonPosition = nil
        return
    end
    local relativePoint = saved.relativePoint or saved[3] or point
    local x = saved.x or saved[4] or 0
    local y = saved.y or saved[5] or 0
    BuffBot.config.buttonPosition = { point = point, relativePoint = relativePoint, x = x, y = y }

    macroButton:ClearAllPoints()
    macroButton:SetPoint(point, UIParent, relativePoint, x, y)
end

--#################### UI Functions ##########################
local function stopMovingMacroButton()
    macroButton:SetScript('OnMouseUp', nil);
    macroButton:SetMovable(false);
    macroButton:StopMovingOrSizing();
    if (macroButton.draggableOverlay ~= nil) then
        macroButton.draggableOverlay:Hide()
    end
    -- Save plain values only; the anchor frame can't be stored in saved variables
    local point, _, relativePoint, x, y = macroButton:GetPoint()
    BuffBot.config.buttonPosition = { point = point, relativePoint = relativePoint, x = x, y = y }
end

local function moveMacroButton()
    macroButton:SetScript('OnMouseUp', stopMovingMacroButton);
    macroButton:SetMovable(true);
    macroButton:StartMoving();
end

macroButton = CreateFrame("Button", "BUFFBOT_MacroButton", UIParent, "SecureActionButtonTemplate")
-- The secure handler only acts on the down or the up click, depending on ActionButtonUseKeyDown
macroButton:RegisterForClicks("AnyUp", "AnyDown")
macroButton:SetAttribute("type1", "macro") -- left click triggers macro
macroButton:SetSize(48, 48)
macroButton:SetClampedToScreen(true);
BuffBot.SetMacroButtonDefaultPosition()

macroButton:SetScript('OnMouseDown', function(_, button)
    if (button == LEFTBUTTON and IsAltKeyDown()) then
        if (macroButton.draggableOverlay == nil) then
            macroButton.draggableOverlay = macroButton:CreateTexture(nil, "OVERLAY")
            macroButton.draggableOverlay:SetAllPoints()
            macroButton.draggableOverlay:SetColorTexture(0, 0.7, 0.7, 0.5)
        else
            macroButton.draggableOverlay:Show()
        end
        moveMacroButton()
    end
end)


BuffBot.suggestionList = {}
function BuffBot.UpdateSuggestionList()
    for i = 1, #BuffBot.suggestionList, 1 do
        BuffBot.suggestionList[i]:SetText("")
        BuffBot.suggestionList[i]:Hide()
    end

    if not BuffBot.config.SUGGESTION_LIST then return end
    -- Same list and skip rules as the button, so they always agree
    local missing = BuffBot.MissingBuffs()
    for i = 1, math.min(#missing, 5) do
        if not BuffBot.suggestionList[i] then
            BuffBot.suggestionList[i] = macroButton:CreateFontString(nil, "OVERLAY", "GameTooltipText")
            BuffBot.suggestionList[i]:SetPoint("TOPLEFT", macroButton, 0, -35 + (i * -15))
        end
        BuffBot.suggestionList[i]:SetText(BuffBot.DisplayName(missing[i]))
        BuffBot.suggestionList[i]:Show()
    end
end

--- Namespacing  ---
BuffBot.macroButton = macroButton;
