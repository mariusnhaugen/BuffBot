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

    it("sends on a registered prefix and records the message", function()
        local h = Addon.load({ class = "PALADIN" })
        assert.equal(0, send(h, "BB:v1:K"))
        assert.same({ "BB:v1:K" }, h:sent())
        assert.equal("RAID", h.state.sent[1].chatType)
        assert.equal(1, select(-1, h.env.C_ChatInfo.SendAddonMessage("Other", "x", "RAID")))
    end)

    it("returns the result last, as the deprecation wrapper does", function()
        local h = Addon.load({ class = "PALADIN" })
        assert.is_nil((h.env.C_ChatInfo.SendAddonMessage("BuffBot", "x", "RAID")))
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

    it("can force a result, such as a lockdown", function()
        local h = Addon.load({ class = "PALADIN" })
        h.state.sendResult = 11
        assert.equal(11, send(h, "x"))
        assert.same({}, h:sent())
    end)

    it("prints messages received on the BuffBot prefix in debug mode", function()
        local h = Addon.load({ class = "PALADIN", config = { DEBUG_MODE = true } })
        h:receive("Bob Smith", "BB:v1:K")
        h:receive("Bob Smith", "other", { prefix = "OtherAddon" })
        assert.is_true(h:printed("BuffBot message from Bob Smith on RAID: BB:v1:K"))
        assert.is_false(h:printed("other"))
    end)

    it("lets a spec pick math.random's result", function()
        local h = Addon.load({ class = "PALADIN" })
        h.state.random = function() return 0.25 end
        assert.equal(0.25, h.env.math.random())
    end)
end)
