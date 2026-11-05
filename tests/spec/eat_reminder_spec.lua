local Addon = require("helpers.load_addon")

describe("eat reminder", function()
    local function leveling(opts)
        opts = opts or {}
        opts.level = opts.level or 30
        opts.config = opts.config or { EAT_REMINDER = true }
        local h = Addon.load(opts)
        h:refresh()
        return h
    end

    it("is off by default", function()
        local h = Addon.load({ level = 30 })
        h:refresh()
        assert.is_false(h.button:IsShown())
        assert.same({}, h:suggestions())
    end)

    it("shows the button and text with no macro when not Well Fed", function()
        local h = leveling()
        assert.is_true(h.button:IsShown())
        assert.is_nil(h.button:GetAttribute("macrotext1"))
        assert.is_truthy(h.button:GetNormalTexture())
        assert.same({ "Eat food (Well Fed)" }, h:suggestions())
    end)

    it("clears a cast's macro, so a press can't repeat the last buff", function()
        local h = leveling({ class = "PRIEST", known = { "Power Word: Fortitude" } })
        assert.is_truthy(h.button:GetAttribute("macrotext1"))
        h:give("Power Word: Fortitude")
        assert.is_true(h.button:IsShown())
        assert.is_nil(h.button:GetAttribute("macrotext1"))
    end)

    it("hides once Well Fed, and comes back when it drops", function()
        local h = leveling()
        h:give("Well Fed")
        assert.is_false(h.button:IsShown())
        h:remove("Well Fed")
        assert.is_true(h.button:IsShown())
    end)

    it("doesn't count as missing early while Well Fed is running out", function()
        local h = leveling()
        h:give("Well Fed", { duration = 900, remaining = 60 })
        assert.is_false(h.button:IsShown())
    end)

    it("stays quiet while eating", function()
        local h = leveling()
        h:give("Food")
        assert.is_false(h.button:IsShown())
    end)

    it("stays quiet at the level cap", function()
        local h = leveling({ level = 60 })
        assert.is_false(h.button:IsShown())
    end)

    it("comes after every real buff", function()
        local h = leveling({ class = "PRIEST", known = { "Power Word: Fortitude" } })
        assert.equal("Power Word: Fortitude", h:shown())
        assert.same({ "Power Word: Fortitude", "Eat food (Well Fed)" }, h:suggestions())
    end)

    it("hides in combat, and comes back after", function()
        local h = leveling()
        h:enterCombat()
        assert.is_false(h.button:IsShown())
        h:leaveCombat()
        assert.is_true(h.button:IsShown())
    end)

    it("stays quiet while dead and in a battleground", function()
        local h = leveling()
        h:die()
        assert.is_false(h.button:IsShown())

        local pvp = leveling()
        pvp.state.instanceType = "pvp"
        pvp:refresh()
        assert.is_false(pvp.button:IsShown())
    end)

    it("shows in /bb status", function()
        local h = leveling()
        h:slash("status")
        assert.is_true(h:printed("Next: Well Fed on you"))
    end)
end)
