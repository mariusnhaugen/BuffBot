local Addon = require("helpers.load_addon")

describe("saved config", function()
    it("uses defaults on first load", function()
        local h = Addon.load()
        assert.same({
            HIDE_ICON = false,
            SUGGESTION_LIST = true,
            DEBUG_MODE = false,
            BLOODRAGE = false,
            WISDOM_SELF = false,
            STRICT_ARMOR = false,
            IGNORE_THORNS = false,
            IGNORE_DAMPEN = false,
            CHEETAH_REMINDER = true,
        }, h.ns.config)
        assert.equal(h.ns.config, h.env.BuffBotConfig)
    end)

    it("prints the load message and the drag hint on first load", function()
        local h = Addon.load()
        assert.is_true(h:printed("Loaded. /bb"))
        assert.is_true(h:printed("You can drag the BuffBot button by holding Alt."))
    end)

    it("uses the saved config when present", function()
        local saved = { SUGGESTION_LIST = false, DEBUG_MODE = false }
        local h = Addon.load({ saved = saved })
        assert.equal(saved, h.ns.config)
    end)

    it("restores a saved button position", function()
        local h = Addon.load({ saved = { buttonPosition = { "TOPLEFT", "UIParent", "TOPLEFT", 10, -20 } } })
        assert.same({ "TOPLEFT", "UIParent", "TOPLEFT", 10, -20 }, { h.button:GetPoint() })
        assert.is_false(h:printed("You can drag"))
    end)

    it("writes the config back on logout", function()
        local h = Addon.load()
        h.ns.config.IGNORE_THORNS = true
        h.env.BuffBotConfig = nil
        h:fire("PLAYER_LOGOUT")
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

    it("/bb buffs dumps the current buff list", function()
        local h = Addon.load({ class = "WARRIOR", known = { "Battle Shout" } })
        h:slash("buffs")
        assert.same({ "Battle Shout" }, h.state.dumped)
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
    local function openPanel(opts)
        local h = Addon.load(opts)
        h:slash("")
        return h
    end

    local function checkbox(h, label)
        return assert(h.env["BuffBotCheckbox" .. label], "missing checkbox " .. label)
    end

    local checkboxes = {
        ["Show Suggestion List"] = "SUGGESTION_LIST",
        ["Strict Mage Armors"] = "STRICT_ARMOR",
        ["Skip Dampen Magic"] = "IGNORE_DAMPEN",
        ["Include Bloodrage (Buggy)"] = "BLOODRAGE",
        ["Recommend Blessing of Wisdom"] = "WISDOM_SELF",
        ["Skip Thorns"] = "IGNORE_THORNS",
        ["Reminder to leave Cheetah"] = "CHEETAH_REMINDER",
    }

    for label, key in pairs(checkboxes) do
        it("'" .. label .. "' reflects and toggles " .. key, function()
            local h = openPanel()
            local check = checkbox(h, label)
            local initial = h.ns.config[key]
            assert.equal(initial, check:GetChecked())
            check:Click()
            assert.equal(not initial, h.ns.config[key])
            check:Click()
            assert.equal(initial, h.ns.config[key])
        end)
    end

    it("toggling a class setting takes effect immediately", function()
        local h = openPanel({ class = "DRUID", known = { "Thorns" } })
        assert.equal("Thorns", h:shown())
        checkbox(h, "Skip Thorns"):Click()
        assert.is_nil(h:shown())
    end)

    it("reset button moves the cast button back to the default position", function()
        local h = openPanel()
        h.button:SetPoint("TOPLEFT", h.env.UIParent, "TOPLEFT", 1, 1)
        local reset
        for _, frame in ipairs(h.state.frames) do
            if frame:GetText() == "Reset Button Position" then reset = frame end
        end
        assert.is_not_nil(reset)
        reset:Click()
        assert.same({ "CENTER", h.env.UIParent, "CENTER", 100, 0 }, { h.button:GetPoint() })
    end)

    it("is painted only once", function()
        local h = openPanel()
        local count = #h.state.frames
        h:slash("")
        assert.equal(count, #h.state.frames)
    end)
end)
