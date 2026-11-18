local _, BuffBot = ...

-- The Class Buff Order and Paladin Blessings pages: a grid of short lists, one per
-- class (and per raid role), each row with a button to leave it out or put
-- it back, and up and down arrows. What the lists mean, and how they're saved, is in Lists.lua.

local CLASSES = { "WARRIOR", "ROGUE", "HUNTER", "MAGE", "WARLOCK", "PRIEST", "DRUID", "SHAMAN", "PALADIN" }
local ROLES = { "tank", "melee", "ranged", "caster", "healer" }
local ROLE_NAMES = { tank = "Tank", melee = "Melee", ranged = "Ranged", caster = "Caster", healer = "Healer" }

-- Each list is a title over an inset box, as Baganator's lists are. PAD is
-- the space inside the box, COLUMN_GAP the space between boxes.
local ROW_HEIGHT, HEADER_HEIGHT, GAP, PAD, COLUMN_GAP = 22, 20, 20, 4, 16
local LEFT, COLUMN_WIDTH, SECTION_GAP = 16, 192, 26
-- The fixed title, intro and Reset all above the scrolling lists
local TOP = 76

-- An atlas: the red no-entry sign Baganator uses for its delete buttons
local ON_ICON = "transmog-icon-remove"
local OFF_ICON = "Interface\\PaperDollInfoFrame\\Character-Plus"

local UNKNOWN_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

-- What the cast-order entries that stand for a pick are called
local PICKS = {
    Unique = { MAGE = "Armor", PALADIN = "Aura", WARLOCK = "Demon armor" },
    Imbue = "Weapon imbue",
    Blessing = "Blessings",
}
local PICK_TOOLTIPS = {
    -- Warlocks have no pick: any of their armors counts
    Unique = { MAGE = "The armor picked on the main BuffBot page.", PALADIN = "The aura picked on the main BuffBot page." },
    Imbue = "The imbue picked on the main BuffBot page.",
    Blessing = "Your blessings: on yourself, your party, and your share in a raid.",
}

local function EntryLabel(key, name)
    local pick = PICKS[name]
    if type(pick) == "table" then return pick[key] or name end
    if pick then return pick end
    local label = BuffBot.SpellName(name) or name
    return label
end

-- The icon of what an entry casts. An entry that stands for a pick shows
-- the pick from the main page; a poison shows the poison picked for that hand.
local function EntryIcon(key, name)
    local poison = BuffBot.WeaponPoisons[name]
    if poison then return BuffBot.PoisonIcon(BuffBot.config[poison.setting]) or UNKNOWN_ICON end
    local spell = name
    if name == "Unique" then
        spell = key == "MAGE" and BuffBot.config.MAGE_ARMOR
            or key == "PALADIN" and BuffBot.config.PALADIN_AURA or "Demon Armor"
    elseif name == "Imbue" then
        spell = BuffBot.config.SHAMAN_IMBUE
    elseif name == "Blessing" then
        spell = BuffBot.config.PALADIN_BLESSING
    end
    local spellID = BuffBot.SpellID(spell)
    return spellID and C_Spell.GetSpellTexture(spellID) or UNKNOWN_ICON
end

local function ClassTitle(class)
    local name = LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[class]
        or class:sub(1, 1) .. class:sub(2):lower()
    local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    if color and color.colorStr then return "|c" .. color.colorStr .. name .. "|r" end
    return name
end

local function SetTooltip(frame, text)
    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(text, 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local function ArrowButton(parent, direction)
    -- A bit taller than the row: the arrow textures have empty edges
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(24, 24)
    local base = "Interface\\Buttons\\UI-ScrollBar-Scroll" .. direction .. "Button-"
    button:SetNormalTexture(base .. "Up")
    button:SetPushedTexture(base .. "Down")
    button:SetDisabledTexture(base .. "Disabled")
    button:SetHighlightTexture(base .. "Highlight", "ADD")
    return button
end

-- One list: a title with a reset button that shows once the list is edited,
-- then an inset box with a row per entry: the on/off box, the name, and the
-- arrows on the right. The entries of a list never change in number, so the
-- rows are made once and refilled. boxRows sizes the box, so the boxes in a
-- line of the grid are the same height.
local function CreateOrderList(parent, kind, key, title, width, boxRows)
    local list = CreateFrame("Frame", nil, parent)
    list.kind, list.key = kind, key
    local count = #BuffBot.DefaultListRows(kind, key)
    local boxWidth = width - COLUMN_GAP
    list:SetSize(boxWidth, HEADER_HEIGHT + boxRows * ROW_HEIGHT + 2 * PAD)

    list.title = list:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    list.title:SetPoint("TOPLEFT", 4, 0)
    list.title:SetText(title)

    list.reset = CreateFrame("Button", nil, list)
    list.reset:SetSize(14, 14)
    list.reset:SetPoint("LEFT", list.title, "RIGHT", 4, 0)
    list.reset:SetNormalTexture("Interface\\Buttons\\UI-RefreshButton")
    list.reset:SetHighlightTexture("Interface\\Buttons\\UI-RefreshButton", "ADD")
    SetTooltip(list.reset, "Reset this list")
    list.reset:SetScript("OnClick", function()
        BuffBot.ResetList(kind, key)
        list:Refresh()
    end)

    list.box = CreateFrame("Frame", nil, list, "InsetFrameTemplate")
    list.box:SetPoint("TOPLEFT", 0, -HEADER_HEIGHT)
    list.box:SetSize(boxWidth, boxRows * ROW_HEIGHT + 2 * PAD)

    -- The arrows move an entry one step, or with Shift all the way
    local function Move(index, step)
        local rows = BuffBot.ListRows(kind, key)
        local target = index + step
        if IsShiftKeyDown() then target = step < 0 and 1 or #rows end
        if target < 1 or target > #rows or target == index then return end
        table.insert(rows, target, table.remove(rows, index))
        BuffBot.SaveList(kind, key, rows)
        list:Refresh()
        list.rows[target].flash:Show()
        C_Timer.After(0.3, function() list.rows[target].flash:Hide() end)
    end

    list.rows = {}
    for index = 1, count do
        -- A button only for the hover highlight, as on Baganator's rows
        local row = CreateFrame("Button", nil, list.box)
        row:SetSize(boxWidth - 2 * PAD, ROW_HEIGHT)
        row:SetPoint("TOPLEFT", PAD, -PAD - (index - 1) * ROW_HEIGHT)
        row:SetHighlightAtlas("auctionhouse-ui-row-highlight")

        row.flash = row:CreateTexture(nil, "BACKGROUND")
        row.flash:SetAllPoints()
        row.flash:SetColorTexture(1, 0.82, 0, 0.15)
        row.flash:Hide()

        -- The buff's icon, in the same place as the button below. Only a
        -- picture: hovering it is hovering the row, which swaps in the button.
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(16, 16)
        row.icon:SetPoint("LEFT", 2, 0)
        row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        -- A red no-entry sign takes an entry off the list, a green + puts it back
        row.toggle = CreateFrame("Button", nil, row)
        row.toggle:SetSize(14, 14)
        row.toggle:SetPoint("LEFT", 3, 0)
        row.toggle.icon = row.toggle:CreateTexture(nil, "ARTWORK")
        row.toggle.icon:SetAllPoints()
        row.toggle:SetScript("OnClick", function()
            BuffBot.SetListEntry(kind, key, row.name, not row.on)
            list:Refresh()
        end)
        row.toggle:SetScript("OnEnter", function(self)
            row.UpdateHover()
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(row.on and "Ignore" or "Suggest")
            GameTooltip:Show()
        end)
        row.toggle:SetScript("OnLeave", function()
            GameTooltip:Hide()
            row.UpdateHover()
        end)

        row.down = ArrowButton(row, "Down")
        row.down:SetPoint("RIGHT", 2, 0)
        row.down:SetScript("OnClick", function() Move(index, 1) end)
        row.up = ArrowButton(row, "Up")
        row.up:SetPoint("RIGHT", row.down, "LEFT", 4, 0)
        row.up:SetScript("OnClick", function() Move(index, -1) end)

        -- An entry that's on shows its icon, swapped for the remove sign
        -- while the row is under the mouse; one that's off always shows the
        -- +. Moving onto the row's own buttons leaves the row, so they check
        -- again too.
        function row.UpdateHover()
            local hovered = row:IsMouseOver()
            local showIcon = row.on and not hovered
            row.toggle:SetShown(not showIcon)
            row.icon:SetShown(showIcon)
            -- The highlight only follows the row itself, so hold it while a
            -- button on the row is under the mouse
            if hovered then row:LockHighlight() else row:UnlockHighlight() end
        end
        row:SetScript("OnEnter", function(self)
            row.UpdateHover()
            local tooltip = PICK_TOOLTIPS[self.name]
            if type(tooltip) == "table" then tooltip = tooltip[key] end
            if tooltip then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(tooltip, 1, 1, 1, 1, true)
                GameTooltip:Show()
            end
        end)
        row:SetScript("OnLeave", function()
            GameTooltip:Hide()
            row.UpdateHover()
        end)
        for _, arrow in ipairs({ row.up, row.down }) do
            -- A disabled button skips its enter and leave scripts unless told
            -- otherwise, and the first and last rows each have one
            arrow:SetMotionScriptsWhileDisabled(true)
            arrow:SetScript("OnEnter", row.UpdateHover)
            arrow:SetScript("OnLeave", row.UpdateHover)
        end

        row.label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        row.label:SetPoint("LEFT", row.toggle, "RIGHT", 5, 0)
        row.label:SetPoint("RIGHT", row.up, "LEFT", -2, 0)
        row.label:SetJustifyH("LEFT")
        row.label:SetWordWrap(false)

        list.rows[index] = row
    end

    function list:Refresh()
        local rows = BuffBot.ListRows(kind, key)
        for index, row in ipairs(self.rows) do
            local entry = rows[index]
            row.name, row.on = entry.name, entry.on
            row.label:SetText(EntryLabel(key, entry.name))
            row.icon:SetTexture(EntryIcon(key, entry.name))
            if entry.on then
                row.label:SetTextColor(1, 1, 1)
            else
                row.label:SetTextColor(0.5, 0.5, 0.5)
            end
            if entry.on then
                row.toggle.icon:SetAtlas(ON_ICON)
            else
                row.toggle.icon:SetTexture(OFF_ICON)
            end
            row.up:SetEnabled(index > 1)
            row.down:SetEnabled(index < #rows)
            row.UpdateHover()
        end
        self.reset:SetShown(BuffBot.ListEdited(kind, key))
    end

    list:Refresh()
    return list
end

-- Lists side by side in three columns on parent, from y down, each kept in
-- page.lists. Returns the y below them.
local function Grid(page, parent, kind, keys, titleOf, y)
    local boxRows = 0
    for _, key in ipairs(keys) do
        boxRows = math.max(boxRows, #BuffBot.DefaultListRows(kind, key))
    end
    local rowHeight = HEADER_HEIGHT + boxRows * ROW_HEIGHT + 2 * PAD
    for i, key in ipairs(keys) do
        local list = CreateOrderList(parent, kind, key, titleOf(key), COLUMN_WIDTH, boxRows)
        local column, line = (i - 1) % 3, math.floor((i - 1) / 3)
        list:SetPoint("TOPLEFT", LEFT + column * COLUMN_WIDTH, y - line * (rowHeight + GAP))
        table.insert(page.lists, list)
    end
    local lines = math.ceil(#keys / 3)
    return y - lines * (rowHeight + GAP) + GAP
end

local function Text(parent, font, text, y)
    local line = parent:CreateFontString(nil, "ARTWORK", font)
    line:SetPoint("TOPLEFT", LEFT, y)
    line:SetPoint("RIGHT", parent, "RIGHT", -LEFT, 0)
    line:SetJustifyH("LEFT")
    line:SetText(text)
    return line
end

StaticPopupDialogs.BUFFBOT_RESET_LISTS = {
    text = "Reset every list on this page?",
    button1 = YES or "Yes",
    button2 = NO or "No",
    OnAccept = function(_, page) page:ResetAll() end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

-- A canvas page: title, intro and a Reset all button that stay put, and
-- below them an area with what build adds, which scrolls when scrolls is
-- set. build gets the area and the y to start from, and returns the y below
-- the last thing it added.
local function CreatePage(title, intro, kinds, scrolls, build)
    local page = CreateFrame("Frame")
    page.lists = {}

    Text(page, "GameFontHighlightHuge", title, -12)
    Text(page, "GameFontHighlightSmall", intro, -42)

    local resetAll = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
    resetAll:SetSize(100, 22)
    resetAll:SetPoint("TOPRIGHT", -LEFT, -10)
    resetAll:SetText("Reset all")
    resetAll:SetScript("OnClick", function() StaticPopup_Show("BUFFBOT_RESET_LISTS", nil, nil, page) end)
    page.resetAll = resetAll

    local content
    if scrolls then
        -- The template's scroll bar hangs off the right edge, so leave room
        local scroll = CreateFrame("ScrollFrame", nil, page, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 0, -TOP)
        scroll:SetPoint("BOTTOMRIGHT", -28, 8)
        content = CreateFrame("Frame", nil, scroll)
        scroll:SetScrollChild(content)
        scroll:SetScript("OnSizeChanged", function(_, width) content:SetWidth(width) end)
        page.scroll = scroll
    else
        content = CreateFrame("Frame", nil, page)
        content:SetPoint("TOPLEFT", 0, -TOP)
        content:SetPoint("RIGHT")
    end
    page.content = content

    function page:Refresh()
        for _, list in ipairs(self.lists) do list:Refresh() end
    end
    function page:ResetAll()
        for _, kind in ipairs(kinds) do BuffBot.ResetLists(kind) end
        self:Refresh()
    end
    -- What the Settings window calls on a canvas page: its Defaults button
    -- asks first, so there's no second popup here
    page.OnDefault = page.ResetAll
    page.OnRefresh = page.Refresh
    page.OnCommit = function() end
    page:SetScript("OnShow", page.Refresh)

    local bottom = build(page, content, -4)
    content:SetSize(LEFT + 3 * COLUMN_WIDTH, -bottom + 12)
    return page
end

function BuffBot.RegisterListPages(category)
    -- The Settings API's canvas pages; leave them out on a client without them
    if not Settings.RegisterCanvasLayoutSubcategory then return end

    local cast = CreatePage("Class Buff Order",
        "The order the button casts your own buffs, from top to bottom. Hover a buff and click its icon to ignore it.",
        -- Fits without scrolling
        { "cast" }, false, function(page, content, y)
            y = Grid(page, content, "cast", CLASSES, ClassTitle, y)
            Text(content, "GameFontDisableSmall", "Shift-click an arrow to move a buff to the top or bottom.", y - 8)
            return y - 22
        end)

    local blessing = CreatePage("Paladin Blessings",
        "Which blessing a Paladin gives each class, from top to bottom.",
        { "blessing", "role" }, true, function(page, content, y)
            Text(content, "GameFontNormalSmall",
                "These show the priority orders BuffBot uses by default. You should rarely need to change them, and I don't recommend it. BuffBot uses spec detection and party/raid roles to optimise buffs.",
                y)
            y = y - 48
            Text(content, "GameFontNormalLarge", "Classes", y)
            y = Grid(page, content, "blessing", CLASSES, ClassTitle, y - 30)
            y = y - SECTION_GAP
            Text(content, "GameFontNormalLarge", "Roles: groups and raids", y)
            Text(content, "GameFontNormalSmall",
                "Only change these if you know what you are doing. They are used when coordinating with other BuffBot Paladins.",
                y - 22):SetTextColor(1, 0.2, 0.2)
            Text(content, "GameFontDisableSmall",
                "Keep these the same as other paladins in your raid. Roles are used in groups and raids with roles set, and any time a spec detection determines it would be optimal.",
                y - 38)
            y = Grid(page, content, "role", ROLES, function(role) return ROLE_NAMES[role] end, y - 74)
            Text(content, "GameFontDisableSmall", "Shift-click an arrow to move a blessing to the top or bottom.", y - 8)
            return y - 22
        end)

    BuffBot.listPages = { cast = cast, blessing = blessing }
    Settings.RegisterCanvasLayoutSubcategory(category, cast, "Class Buff Order")
    Settings.RegisterCanvasLayoutSubcategory(category, blessing, "Paladin Blessings")
end
