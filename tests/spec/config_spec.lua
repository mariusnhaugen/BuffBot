local Addon = require("helpers.load_addon")

describe("saved config", function()
    it("uses defaults on first load", function()
        local h = Addon.load()
        assert.same({
            HIDE_ICON = false,
            HIDE_TEXT = false,
            DEBUG_MODE = false,
            BLOODRAGE = false,
            PALADIN_BLESSING = "Blessing of Might",
            RIGHTEOUS_FURY = false,
            STRICT_ARMOR = false,
            IGNORE_THORNS = false,
            IGNORE_DAMPEN = false,
            CHEETAH_REMINDER = true,
            SHAMAN_IMBUE = "Rockbiter Weapon",
            ROGUE_POISON_MAINHAND = "Instant Poison",
            ROGUE_POISON_OFFHAND = "Instant Poison",
            TRACK_TREASURE = true,
            GROUP_BUFFING = true,
        }, h.ns.config)
        assert.equal(h.ns.config, h.env.BuffBotConfig)
    end)

    it("keeps the tracker per character, unpicked on first load", function()
        local h = Addon.load()
        assert.same({ TRACKER = "" }, h.ns.charConfig)
        assert.equal(h.ns.charConfig, h.env.BuffBotCharConfig)
    end)

    it("loads a saved tracker", function()
        local h = Addon.load({ charSaved = { TRACKER = "Find Herbs" } })
        assert.equal("Find Herbs", h:settingNamed("Auto tracking"):GetValue())
    end)

    it("prints the load message and the drag hint on first load", function()
        local h = Addon.load()
        assert.is_true(h:printed("Loaded. /bb"))
        assert.is_true(h:printed("v" .. h.env.C_AddOns.GetAddOnMetadata("BuffBot", "Version") .. "|r"))
        assert.is_true(h:printed("You can drag the BuffBot button by holding Alt."))
    end)

    it("uses the saved config when present", function()
        local saved = { HIDE_TEXT = true, DEBUG_MODE = false }
        local h = Addon.load({ saved = saved })
        assert.equal(saved, h.ns.config)
        assert.is_true(h.ns.config.HIDE_TEXT)
    end)

    it("turns an old SUGGESTION_LIST into HIDE_TEXT", function()
        local h = Addon.load({ saved = { SUGGESTION_LIST = false } })
        assert.is_true(h.ns.config.HIDE_TEXT)
        assert.is_nil(h.ns.config.SUGGESTION_LIST)
        h = Addon.load({ saved = { SUGGESTION_LIST = true } })
        assert.is_false(h.ns.config.HIDE_TEXT)
        assert.is_nil(h.ns.config.SUGGESTION_LIST)
    end)

    it("drops the old RAID_BUFFING", function()
        local h = Addon.load({ saved = { RAID_BUFFING = true } })
        assert.is_nil(h.ns.config.RAID_BUFFING)
    end)

    it("turns an old WISDOM_SELF into PALADIN_BLESSING", function()
        local h = Addon.load({ saved = { WISDOM_SELF = true } })
        assert.equal("Blessing of Wisdom", h.ns.config.PALADIN_BLESSING)
        assert.is_nil(h.ns.config.WISDOM_SELF)
        h = Addon.load({ saved = { WISDOM_SELF = false } })
        assert.equal("Blessing of Might", h.ns.config.PALADIN_BLESSING)
        assert.is_nil(h.ns.config.WISDOM_SELF)
    end)

    it("fills in settings missing from an older saved config", function()
        local h = Addon.load({ saved = { HIDE_TEXT = true, CHEETAH_REMINDER = false } })
        assert.is_true(h.ns.config.HIDE_TEXT)
        assert.is_false(h.ns.config.CHEETAH_REMINDER)
        assert.is_false(h.ns.config.IGNORE_THORNS)
        assert.is_false(h.ns.config.BLOODRAGE)
    end)

    it("an older saved config without the Cheetah setting gets the default", function()
        local h = Addon.load({
            class = "HUNTER",
            known = { "Aspect of the Hawk" },
            saved = { HIDE_TEXT = false },
        })
        assert.is_true(h.ns.config.CHEETAH_REMINDER)
        h.state:giveAura("Aspect of the Cheetah")
        h:refresh()
        assert.equal("Aspect of the Hawk", h:shown())
    end)

    it("restores a saved button position", function()
        local h = Addon.load({ saved = { buttonPosition = { point = "TOPLEFT", relativePoint = "TOPLEFT", x = 10, y = -20 } } })
        assert.same({ "TOPLEFT", h.env.UIParent, "TOPLEFT", 10, -20 }, { h.button:GetPoint() })
        assert.is_false(h:printed("You can drag"))
    end)

    it("restores a position saved in the old list format", function()
        local h = Addon.load({ saved = { buttonPosition = { "TOPLEFT", {}, "TOPLEFT", 10, -20 } } })
        assert.same({ "TOPLEFT", h.env.UIParent, "TOPLEFT", 10, -20 }, { h.button:GetPoint() })
        assert.same({ point = "TOPLEFT", relativePoint = "TOPLEFT", x = 10, y = -20 }, h.ns.config.buttonPosition)
    end)

    it("restores an old-format position whose anchor frame was lost", function()
        local h = Addon.load({ saved = { buttonPosition = { [1] = "CENTER", [3] = "CENTER", [4] = 30, [5] = 40 } } })
        assert.same({ "CENTER", h.env.UIParent, "CENTER", 30, 40 }, { h.button:GetPoint() })
    end)

    it("falls back to the default position for an unreadable saved position", function()
        local h = Addon.load({ saved = { buttonPosition = {} } })
        assert.same({ "CENTER", h.env.UIParent, "CENTER", 100, 0 }, { h.button:GetPoint() })
        assert.is_nil(h.ns.config.buttonPosition)
    end)

    it("saves the dragged position without the anchor frame", function()
        local h = Addon.load()
        h.state.altDown = true
        h.button:GetScript("OnMouseDown")(h.button, "LeftButton")
        h.button:SetPoint("TOPLEFT", h.env.UIParent, "TOPLEFT", 50, -60)
        h.button:GetScript("OnMouseUp")(h.button, "LeftButton")
        assert.same({ point = "TOPLEFT", relativePoint = "TOPLEFT", x = 50, y = -60 }, h.ns.config.buttonPosition)
    end)

    it("changes the saved settings table directly", function()
        local h = Addon.load()
        h.ns.config.IGNORE_THORNS = true
        assert.equal(h.ns.config, h.env.BuffBotConfig)
        assert.is_true(h.env.BuffBotConfig.IGNORE_THORNS)
    end)
end)

describe("slash commands", function()
    it("registers /bb and /buffbot", function()
        local h = Addon.load()
        assert.equal("/bb", h.env.SLASH_BUFFBOTSETTINGS1)
        assert.equal("/buffbot", h.env.SLASH_BUFFBOTSETTINGS2)
    end)

    it("/bb opens the settings panel", function()
        local h = Addon.load()
        h:slash("")
        assert.equal("BuffBot", h.state.openedCategory)
    end)

    it("/bb buffs prints the current buff list", function()
        local h = Addon.load({ class = "MAGE", known = { "Arcane Intellect", "Dampen Magic" } })
        h:slash("buffs")
        assert.is_true(h:printed("BuffBot buffs: Arcane Intellect, Dampen Magic"))
    end)

    it("/bb buffs with an empty list says so", function()
        local h = Addon.load({ class = "WARRIOR" })
        h:slash("buffs")
        assert.is_true(h:printed("BuffBot buffs: none"))
    end)

    it("/bb debug toggles debug mode", function()
        local h = Addon.load()
        h:slash("debug")
        assert.is_true(h.ns.config.DEBUG_MODE)
        assert.is_true(h:printed("BuffBot Debug Mode - true"))
        h:slash("debug")
        assert.is_false(h.ns.config.DEBUG_MODE)
    end)
end)

describe("settings panel", function()
    local checkboxes = {
        ["Hide Icon"] = "HIDE_ICON",
        ["Hide Text"] = "HIDE_TEXT",
        ["Strict Mage Armors"] = "STRICT_ARMOR",
        ["Skip Dampen Magic"] = "IGNORE_DAMPEN",
        ["Always try Bloodrage out of combat"] = "BLOODRAGE",
        ["Recommend Righteous Fury"] = "RIGHTEOUS_FURY",
        ["Skip Thorns"] = "IGNORE_THORNS",
        ["Reminder to leave Cheetah"] = "CHEETAH_REMINDER",
        ["Auto Find Treasure"] = "TRACK_TREASURE",
    }

    for label, key in pairs(checkboxes) do
        it("'" .. label .. "' is a checkbox bound to " .. key, function()
            local h = Addon.load()
            local control = h:control(label)
            assert.equal("checkbox", control.kind)
            assert.is_not_nil(control.tooltip)
            local setting = control.setting
            assert.equal(h.ns.GetDefaultConfig()[key], setting.default)
            local initial = h.ns.config[key]
            assert.equal(initial, setting:GetValue())
            setting:SetValue(not initial)
            assert.equal(not initial, h.ns.config[key])
            assert.equal(not initial, h.env.BuffBotConfig[key])
        end)
    end

    it("registers the page once, after the saved config loads", function()
        local h = Addon.load({ saved = { IGNORE_THORNS = true } })
        assert.is_true(h.state.categories.BuffBot.registered)
        assert.is_true(h:settingNamed("Skip Thorns"):GetValue())
    end)

    it("toggling a class setting takes effect immediately", function()
        local h = Addon.load({ class = "DRUID", known = { "Thorns" } })
        assert.equal("Thorns", h:shown())
        h:settingNamed("Skip Thorns"):SetValue(true)
        assert.is_nil(h:shown())
    end)

    it("'Hide Text' hides the suggestion list straight away", function()
        local h = Addon.load({ class = "PRIEST", known = { "Power Word: Fortitude", "Inner Fire" } })
        assert.are_not.same({}, h:suggestions())
        h:settingNamed("Hide Text"):SetValue(true)
        assert.same({}, h:suggestions())
    end)

    it("puts tracking, group, then the class settings, under headers after the button", function()
        local h = Addon.load()
        local order = {}
        for _, init in ipairs(h.state.categories.BuffBot.initializers) do
            if init.kind == "header" then
                table.insert(order, init.name)
            elseif init.kind == "button" then
                table.insert(order, "button")
            elseif init.setting.name == "Auto tracking" or init.setting.name == "Auto Find Treasure"
                or init.setting.name == "Buff your group" then
                table.insert(order, init.setting.name)
            end
        end
        assert.same({ "button", "Tracking", "Auto tracking", "Auto Find Treasure", "Group", "Buff your group",
            "Class Settings" }, order)
    end)

    local function resetButton(h)
        for _, init in ipairs(h.state.categories.BuffBot.initializers) do
            if init.kind == "button" and init.buttonText == "Reset Button Position" then return init end
        end
        error("no reset button")
    end

    it("reset button moves the cast button back to the default position", function()
        local h = Addon.load()
        h.button:SetPoint("TOPLEFT", h.env.UIParent, "TOPLEFT", 1, 1)
        resetButton(h).onClick()
        assert.same({ "CENTER", h.env.UIParent, "CENTER", 100, 0 }, { h.button:GetPoint() })
    end)

    it("reset button does nothing in combat", function()
        local h = Addon.load()
        h.button:SetPoint("TOPLEFT", h.env.UIParent, "TOPLEFT", 1, 1)
        h:enterCombat()
        resetButton(h).onClick()
        assert.same({ "TOPLEFT", h.env.UIParent, "TOPLEFT", 1, 1 }, { h.button:GetPoint() })
        assert.is_true(h:printed("can't move the button in combat"))
    end)
end)
