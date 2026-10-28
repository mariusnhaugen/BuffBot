local Addon = require("helpers.load_addon")

-- The add-on message mocks the protocol specs build on
describe("add-on messages", function()
    local function send(h, text)
        return select(-1, h.env.C_ChatInfo.SendAddonMessage("BuffBot", text, "RAID"))
    end

    it("registers the BuffBot prefix on load", function()
        local h = Addon.load({ class = "PALADIN" })
        assert.is_true(h.state.prefixes.BuffBot)
    end)

    it("drops sends past 10, and allows 1 more a second", function()
        local h = Addon.load({ class = "PALADIN" })
        for i = 1, 10 do assert.equal(0, send(h, "m" .. i)) end
        assert.equal(3, send(h, "dropped"))
        h.state:advance(1)
        assert.equal(0, send(h, "m11"))
        assert.equal(3, send(h, "dropped"))
        assert.equal(11, #h:sent())
    end)

    it("prints messages received on the BuffBot prefix in debug mode", function()
        local h = Addon.load({ class = "PALADIN", config = { DEBUG_MODE = true } })
        h:receive("Bob Smith", "BB:v1:K")
        h:receive("Bob Smith", "other", { prefix = "OtherAddon" })
        assert.is_true(h:printed("BuffBot message from Bob Smith on RAID: BB:v1:K"))
        assert.is_false(h:printed("other"))
    end)
end)
