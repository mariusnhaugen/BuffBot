local Addon = require("helpers.load_addon")

-- A buff counts as missing when less than 20% of its duration AND less than
-- 5 minutes remain.
describe("buff refresh timing", function()
    local function priest()
        return Addon.load({ class = "PRIEST", known = { "Power Word: Fortitude" } })
    end

    it("a fresh buff is not missing", function()
        local h = priest()
        h:give("Power Word: Fortitude", { duration = 1800 })
        assert.is_nil(h:shown())
    end)

    it("under 20% but 5+ minutes left is not missing", function()
        local h = priest()
        h:give("Power Word: Fortitude", { duration = 1800, remaining = 301 })
        assert.is_nil(h:shown())
    end)

    it("under 20% and under 5 minutes is missing", function()
        local h = priest()
        h:give("Power Word: Fortitude", { duration = 1800, remaining = 299 })
        assert.equal("Power Word: Fortitude", h:shown())
    end)

    it("expiring over time brings the buff back", function()
        local h = priest()
        h:give("Power Word: Fortitude", { duration = 1800 })
        h.state:advance(1800 - 250)
        h:refresh()
        assert.equal("Power Word: Fortitude", h:shown())
    end)

    it("short buffs refresh at 20% of their duration", function()
        local h = priest()
        h:give("Power Word: Fortitude", { duration = 600, remaining = 121 })
        assert.is_nil(h:shown())
        h:give("Power Word: Fortitude", { duration = 600, remaining = 119 })
        assert.equal("Power Word: Fortitude", h:shown())
    end)

    it("permanent auras are never missing", function()
        local h = Addon.load({ class = "PALADIN", known = { "Devotion Aura" } })
        h:give("Devotion Aura", { duration = 0 })
        h.state:advance(100000)
        h:refresh()
        assert.is_nil(h:shown())
    end)
end)
