local Addon = require("helpers.load_addon")

local ALL = { "Blessing of Might", "Blessing of Wisdom", "Blessing of Kings" }

local function paladin(opts)
    opts = opts or {}
    opts.class = "PALADIN"
    opts.known = opts.known or ALL
    return Addon.load(opts)
end

local function names(rows)
    local list = {}
    for _, row in ipairs(rows) do table.insert(list, row.name .. (row.on and "" or " (off)")) end
    return list
end

describe("editable lists", function()
    describe("defaults", function()
        it("cast order starts with Righteous Fury off", function()
            local h = Addon.load()
            assert.same({ "Unique", "Blessing", "Righteous Fury (off)", "Oath of Light" },
                names(h.ns.ListRows("cast", "PALADIN")))
        end)

        it("class blessing lists end with what the class can't use, off", function()
            local h = Addon.load()
            assert.same({ "Blessing of Might", "Blessing of Kings", "Blessing of Wisdom (off)" },
                names(h.ns.ListRows("blessing", "WARRIOR")))
            assert.same({ "Blessing of Wisdom", "Blessing of Kings", "Blessing of Might (off)" },
                names(h.ns.ListRows("blessing", "MAGE")))
            assert.same({ "Blessing of Kings", "Blessing of Wisdom", "Blessing of Might" },
                names(h.ns.ListRows("blessing", "HUNTER")))
        end)

        it("role lists keep the blessings they had, the rest off", function()
            local h = Addon.load()
            assert.same({ "Blessing of Kings", "Blessing of Might" }, h.ns.ListOn("role", "tank"))
            assert.same({ "Blessing of Wisdom", "Blessing of Kings" }, h.ns.ListOn("role", "healer"))
        end)
    end)

    describe("saving", function()
        it("saves nothing for a list back at its default", function()
            local h = Addon.load()
            h.ns.SetListEntry("cast", "DRUID", "Thorns", false)
            assert.is_not_nil(h.ns.config.CAST_ORDER.DRUID)
            h.ns.SetListEntry("cast", "DRUID", "Thorns", true)
            assert.is_nil(h.ns.config.CAST_ORDER.DRUID)
            assert.is_false(h.ns.ListEdited("cast", "DRUID"))
        end)

        it("drops saved entries no longer in the defaults and adds new ones at the end", function()
            local h = Addon.load({ saved = { CAST_ORDER = { PRIEST = {
                { name = "Inner Fire", on = true },
                { name = "Old Buff", on = true },
                { name = "Power Word: Fortitude", on = false },
            } } } })
            assert.same({ "Inner Fire", "Power Word: Fortitude (off)", "Shadowform", "Divine Spirit" },
                names(h.ns.ListRows("cast", "PRIEST")))
        end)

        it("resets one list, or every list of a kind", function()
            local h = Addon.load()
            h.ns.SetListEntry("cast", "DRUID", "Thorns", false)
            h.ns.SetListEntry("cast", "MAGE", "Dampen Magic", false)
            h.ns.ResetList("cast", "DRUID")
            assert.is_nil(h.ns.config.CAST_ORDER.DRUID)
            assert.is_not_nil(h.ns.config.CAST_ORDER.MAGE)
            h.ns.ResetLists("cast")
            assert.same({}, h.ns.config.CAST_ORDER)
        end)
    end)

    describe("moving the old checkboxes", function()
        -- { old key, value, class, entry, on afterwards }
        local cases = {
            { "IGNORE_THORNS", true, "DRUID", "Thorns", false },
            { "IGNORE_DAMPEN", true, "MAGE", "Dampen Magic", false },
            { "IGNORE_INNER_FIRE", true, "PRIEST", "Inner Fire", false },
            { "IGNORE_LIGHTNING_SHIELD", true, "SHAMAN", "Lightning Shield", false },
            { "RIGHTEOUS_FURY", true, "PALADIN", "Righteous Fury", true },
        }
        for _, case in ipairs(cases) do
            local key, value, class, entry, on = unpack(case)
            it(key .. " = " .. tostring(value) .. " turns " .. entry .. (on and " on" or " off"), function()
                local h = Addon.load({ saved = { [key] = value } })
                assert.is_nil(h.ns.config[key])
                for _, row in ipairs(h.ns.ListRows("cast", class)) do
                    if row.name == entry then assert.equal(on, row.on) end
                end
                assert.is_true(h.ns.ListEdited("cast", class))
            end)
        end

        it("saves nothing for an old checkbox left at its default", function()
            local h = Addon.load({ saved = { IGNORE_THORNS = false, RIGHTEOUS_FURY = false } })
            assert.is_nil(h.ns.config.IGNORE_THORNS)
            assert.is_nil(h.ns.config.RIGHTEOUS_FURY)
            assert.same({}, h.ns.config.CAST_ORDER)
        end)

        it("keeps Thorns off for someone who had skipped it", function()
            local h = Addon.load({ class = "DRUID", known = { "Mark of the Wild", "Thorns" },
                saved = { IGNORE_THORNS = true } })
            assert.same({ "Mark of the Wild" }, h:buffUp())
        end)
    end)

    describe("cast order", function()
        it("casts in the saved order", function()
            local h = Addon.load({ class = "PRIEST", known = { "Power Word: Fortitude", "Inner Fire" } })
            assert.same({ "Power Word: Fortitude", "Inner Fire" }, h:buffUp())
            h = Addon.load({ class = "PRIEST", known = { "Power Word: Fortitude", "Inner Fire" } })
            local rows = h.ns.ListRows("cast", "PRIEST")
            table.insert(rows, 1, table.remove(rows, 4))
            h.ns.SaveList("cast", "PRIEST", rows)
            assert.same({ "Inner Fire", "Power Word: Fortitude" }, h:buffUp())
        end)

        it("notes an entry turned off in /bb status", function()
            local h = Addon.load({ class = "DRUID", known = { "Mark of the Wild", "Thorns" } })
            h:listEntry("cast", "DRUID", "Thorns", false)
            assert.is_true(h.ns.IndexOf("Thorns (off in settings)", h.ns.leftOff) ~= nil)
        end)

        it("turning off the armor entry leaves the armor out", function()
            local h = Addon.load({ class = "MAGE", known = { "Frost Armor", "Arcane Intellect" } })
            assert.same({ "Frost Armor", "Arcane Intellect" }, h:buffUp())
            h = Addon.load({ class = "MAGE", known = { "Frost Armor", "Arcane Intellect" },
                lists = { { "cast", "MAGE", "Unique", false } } })
            assert.same({ "Arcane Intellect" }, h:buffUp())
        end)
    end)

    describe("blessings", function()
        it("a class list decides in a party, and can give Warriors Wisdom", function()
            local h = paladin({ lists = {
                { "blessing", "WARRIOR", "Blessing of Might", false },
                { "blessing", "WARRIOR", "Blessing of Kings", false },
                { "blessing", "WARRIOR", "Blessing of Wisdom", true },
            } })
            h:give("Blessing of Might")
            h:joinParty({ { class = "WARRIOR" } })
            assert.same({ "Blessing of Wisdom > party1" }, h:buffUp())
        end)

        it("a reordered class list changes the party blessing", function()
            local h = paladin()
            local rows = h.ns.ListRows("blessing", "HUNTER")
            table.insert(rows, 1, table.remove(rows, 3))
            h.ns.SaveList("blessing", "HUNTER", rows)
            h:give("Blessing of Might")
            h:joinParty({ { class = "HUNTER" } })
            assert.same({ "Blessing of Might > party1" }, h:buffUp())
        end)

        it("a role list decides in a raid", function()
            local h = paladin()
            local rows = h.ns.ListRows("role", "melee")
            table.insert(rows, 1, table.remove(rows, 2))
            h.ns.SaveList("role", "melee", rows)
            h:give("Blessing of Might")
            h:joinRaid({ { class = "WARRIOR" } })
            h:settle()
            assert.same({ "Blessing of Kings > raid2" }, h:buffUp())
        end)

        it("a role list still skips what the class can't use", function()
            local h = paladin({ lists = {
                { "role", "melee", "Blessing of Wisdom", true },
                { "role", "melee", "Blessing of Might", false },
                { "role", "melee", "Blessing of Kings", false },
            } })
            h:give("Blessing of Might")
            h:joinRaid({ { class = "WARRIOR" } })
            h:settle()
            assert.same({}, h:buffUp())
        end)
    end)
end)

describe("list pages", function()
    local function page(h, name) return h.state.canvasPages[name].frame end

    local function listOf(h, pageName, kind, key)
        for _, list in ipairs(page(h, pageName).lists) do
            if list.kind == kind and list.key == key then return list end
        end
        error("no list " .. kind .. " " .. key)
    end

    local function labels(list)
        local texts = {}
        for _, row in ipairs(list.rows) do table.insert(texts, row.label:GetText()) end
        return texts
    end

    it("adds Class Buff Order and Paladin Blessings under the BuffBot page", function()
        local h = Addon.load()
        assert.equal(h.state.categories.BuffBot, h.state.canvasPages["Class Buff Order"].parent)
        assert.equal(h.state.categories.BuffBot, h.state.canvasPages["Paladin Blessings"].parent)
        assert.equal(9, #page(h, "Class Buff Order").lists)
        assert.is_nil(page(h, "Class Buff Order").scroll)
        assert.is_not_nil(page(h, "Paladin Blessings").scroll)
        assert.equal(14, #page(h, "Paladin Blessings").lists)
    end)

    it("names the entries that stand for a pick", function()
        local h = Addon.load()
        assert.same({ "Aura", "Blessings", "Righteous Fury", "Oath of Light" },
            labels(listOf(h, "Class Buff Order", "cast", "PALADIN")))
        assert.same({ "Weapon imbue" }, { labels(listOf(h, "Class Buff Order", "cast", "SHAMAN"))[2] })
        assert.same({ "Blessing of Kings", "Blessing of Might", "Blessing of Wisdom" },
            labels(listOf(h, "Paladin Blessings", "role", "tank")))
    end)

    it("arrows move an entry, and the end arrows are off", function()
        local h = Addon.load()
        local list = listOf(h, "Class Buff Order", "cast", "PRIEST")
        assert.is_false(list.rows[1].up:IsEnabled())
        assert.is_false(list.rows[4].down:IsEnabled())
        assert.is_false(list.reset:IsShown())
        list.rows[2].up:Click()
        assert.same({ "Shadowform", "Power Word: Fortitude", "Divine Spirit", "Inner Fire" },
            h.ns.ListOn("cast", "PRIEST"))
        assert.equal("Shadowform", list.rows[1].label:GetText())
        assert.is_true(list.reset:IsShown())
    end)

    it("shift-click moves an entry to the end", function()
        local h = Addon.load()
        local list = listOf(h, "Class Buff Order", "cast", "PRIEST")
        h.state.shiftDown = true
        list.rows[1].down:Click()
        assert.same({ "Shadowform", "Divine Spirit", "Inner Fire", "Power Word: Fortitude" },
            h.ns.ListOn("cast", "PRIEST"))
    end)

    it("the no-entry sign leaves an entry out and greys it, and the + puts it back", function()
        local h = Addon.load({ class = "DRUID", known = { "Thorns" } })
        local list = listOf(h, "Class Buff Order", "cast", "DRUID")
        assert.equal("Thorns", h:shown())
        assert.is_truthy(list.rows[2].toggle.icon.atlas == "transmog-icon-remove")
        list.rows[2].toggle:Click()
        assert.is_nil(h:shown())
        assert.same({ 0.5, 0.5, 0.5 }, list.rows[2].label.textColor)
        assert.is_truthy(list.rows[2].toggle.icon:GetTexture():find("Plus"))
        list.rows[2].toggle:Click()
        assert.equal("Thorns", h:shown())
    end)

    it("shows the buff's icon, swapped for the remove sign on the hovered row, and the + always", function()
        local h = Addon.load({ class = "DRUID", known = { "Thorns" } })
        local list = listOf(h, "Class Buff Order", "cast", "DRUID")
        local row = list.rows[2]
        assert.is_false(row.toggle:IsShown())
        assert.is_true(row.icon:IsShown())
        assert.equal(h.env.C_Spell.GetSpellTexture(h.ns.SpellID("Thorns")), row.icon:GetTexture())
        h.state.mouseOver = row.up
        row.up:GetScript("OnEnter")(row.up)
        assert.is_true(row.toggle:IsShown())
        assert.is_false(row.icon:IsShown())
        h.state.mouseOver = nil
        row.up:GetScript("OnLeave")(row.up)
        assert.is_false(row.toggle:IsShown())
        assert.is_true(row.icon:IsShown())
        h.ns.SetListEntry("cast", "DRUID", "Thorns", false)
        list:Refresh()
        assert.is_true(row.toggle:IsShown())
        assert.is_false(row.icon:IsShown())
    end)

    it("shows the picked imbue's icon for the imbue entry, and a question mark for one it can't find", function()
        local h = Addon.load({ class = "SHAMAN", known = { "Windfury Weapon" }, saved = { SHAMAN_IMBUE = "Windfury Weapon" } })
        local list = listOf(h, "Class Buff Order", "cast", "SHAMAN")
        assert.equal(h.env.C_Spell.GetSpellTexture(h.ns.SpellID("Windfury Weapon")), list.rows[2].icon:GetTexture())
        assert.is_truthy(list.rows[1].icon:GetTexture():find("QuestionMark"))
    end)

    it("the list's reset button puts it back", function()
        local h = Addon.load()
        local list = listOf(h, "Class Buff Order", "cast", "PRIEST")
        list.rows[2].up:Click()
        list.reset:Click()
        assert.is_false(h.ns.ListEdited("cast", "PRIEST"))
        assert.equal("Power Word: Fortitude", list.rows[1].label:GetText())
        assert.is_false(list.reset:IsShown())
    end)

    it("Reset all asks, then resets the class and role lists", function()
        local h = Addon.load()
        local blessings = page(h, "Paladin Blessings")
        h.ns.SetListEntry("blessing", "WARRIOR", "Blessing of Wisdom", true)
        h.ns.SetListEntry("role", "tank", "Blessing of Wisdom", true)
        h.ns.SetListEntry("cast", "DRUID", "Thorns", false)
        h.state.declinePopups = true
        blessings.resetAll:Click()
        assert.same({ "BUFFBOT_RESET_LISTS" }, h.state.popups)
        assert.is_true(h.ns.ListEdited("blessing", "WARRIOR"))
        h.state.declinePopups = false
        blessings.resetAll:Click()
        assert.is_false(h.ns.ListEdited("blessing", "WARRIOR"))
        assert.is_false(h.ns.ListEdited("role", "tank"))
        assert.is_true(h.ns.ListEdited("cast", "DRUID"))
    end)
end)
