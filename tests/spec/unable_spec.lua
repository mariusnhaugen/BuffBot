local Addon = require("helpers.load_addon")

describe("when buffing is impossible", function()
    local h

    before_each(function()
        h = Addon.load({ class = "MAGE", known = { "Arcane Intellect" } })
    end)

    it("hides the button on death", function()
        h:die()
        assert.is_nil(h:shown())
    end)

    it("stays hidden as a ghost", function()
        h:die()
        h:releaseSpirit()
        assert.is_nil(h:shown())
    end)

    it("ignores aura changes while dead", function()
        h:die()
        h:give("Arcane Intellect")
        h:remove("Arcane Intellect")
        assert.is_nil(h:shown())
    end)

    it("comes back after resurrecting", function()
        h:die()
        h:releaseSpirit()
        h:resurrect()
        assert.equal("Arcane Intellect", h:shown())
    end)

    it("comes back when resurrected without releasing", function()
        h:die()
        h.state.dead = false
        h:fire("PLAYER_ALIVE")
        assert.equal("Arcane Intellect", h:shown())
    end)

    it("hides the button on a flight path and comes back on landing", function()
        h:takeTaxi()
        assert.is_nil(h:shown())
        h:landTaxi()
        assert.equal("Arcane Intellect", h:shown())
    end)
end)
