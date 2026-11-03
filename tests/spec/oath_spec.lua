local Addon = require("helpers.load_addon")

-- A Holy Paladin with Oath of Light, already wearing Devotion Aura and Might,
-- and not buffing the group, so only the Oath is left
local function holy(opts)
    opts = opts or {}
    opts.class = "PALADIN"
    opts.known = opts.known or { "Devotion Aura", "Blessing of Might", "Oath of Light" }
    local h = Addon.load(opts)
    h:setting("GROUP_BUFFING", false)
    h:give("Devotion Aura")
    h:give("Blessing of Might")
    return h
end

describe("Oath of Light", function()
    it("is never suggested without the talent", function()
        local h = holy({ known = { "Devotion Aura", "Blessing of Might" } })
        h:joinRaid({ { class = "WARRIOR", mainTank = true } })
        h:settle()
        assert.is_nil(h:shown())
    end)

    it("goes on the main tank", function()
        local h = holy()
        h:joinRaid({ { class = "WARRIOR" }, { class = "WARRIOR", mainTank = true } })
        h:settle()
        assert.same({ "Oath of Light > raid3" }, h:buffUp())
    end)

    it("goes on a tank by role without a main-tank mark", function()
        local h = holy({ saved = { ROLES = { ["raid3"] = "tank" } } })
        h:joinRaid({ { class = "WARRIOR" }, { class = "DRUID" } })
        h:settle()
        assert.same({ "Oath of Light > raid3" }, h:buffUp())
    end)

    it("goes on the player's target when there's no tank in a dungeon", function()
        local h = holy()
        h.state.instanceType = "party"
        h:joinParty({ { class = "WARRIOR" }, { class = "MAGE" } })
        assert.equal("Oath of Light", h:shown())
        assert.equal("target,help,nodead", h:target())
        assert.same({ "Oath of Light > Target" }, h:suggestions())
    end)

    it("goes on the player's target after the raid's blessings", function()
        local h = holy({ known = { "Devotion Aura", "Blessing of Might", "Blessing of Kings", "Oath of Light" } })
        h:setting("GROUP_BUFFING", true)
        h.state.instanceType = "raid"
        h:joinRaid({ { class = "MAGE" } })
        h:settle()
        assert.same({ "Blessing of Kings > raid2", "Oath of Light > Target" }, h:suggestions())
    end)

    it("isn't offered on the player's target outside a dungeon or raid", function()
        local h = holy()
        h:joinParty({ { class = "WARRIOR" }, { class = "MAGE" } })
        h:settle()
        assert.is_nil(h:shown())
    end)

    it("goes on a tank outside a dungeon or raid", function()
        local h = holy({ saved = { ROLES = { ["party1"] = "tank" } } })
        h:joinParty({ { class = "WARRIOR" }, { class = "MAGE" } })
        h:settle()
        assert.same({ "Oath of Light > party1" }, h:buffUp())
    end)

    it("is never offered alone", function()
        local h = holy()
        assert.is_nil(h:shown())
    end)

    it("is never offered on the player, even as a tank", function()
        local h = holy({ known = { "Devotion Aura", "Blessing of Might", "Oath of Light", "Righteous Fury" } })
        h:setting("RIGHTEOUS_FURY", true)
        h:give("Righteous Fury")
        h.state.talents = { 0, 31, 0 }
        assert.equal("tank", h.ns.RoleOf("player"))
        h.state.instanceType = "party"
        h:joinParty({ { class = "MAGE" } })
        assert.equal("target,help,nodead", h:target())
    end)

    it("ignores the player's own Oath on themselves", function()
        local h = holy()
        h.state.instanceType = "party"
        h:joinParty({ { class = "MAGE" } })
        h:give("Oath of Light", { duration = 300 })
        assert.equal("target,help,nodead", h:target())
    end)

    it("comes before the raid's blessings", function()
        local h = holy()
        h:setting("GROUP_BUFFING", true)
        h:joinRaid({ { class = "WARRIOR", mainTank = true } })
        h:settle()
        assert.equal("Oath of Light", h:shown())
        assert.equal("raid2", h:target())
    end)

    it("is never offered in a battleground", function()
        local h = holy()
        h.state.instanceType = "pvp"
        h:joinRaid({ { class = "WARRIOR", mainTank = true } })
        h:settle()
        assert.is_nil(h:shown())
    end)

    describe("once cast", function()
        local function cast(h, unit, opts)
            opts = opts or {}
            opts.unit, opts.duration = unit, 300
            h:give("Oath of Light", opts)
        end

        it("stays on the player's pick over the main tank", function()
            local h = holy()
            h:joinParty({ { class = "WARRIOR" }, { class = "PRIEST" } })
            cast(h, "party2")
            assert.is_nil(h:shown())
        end)

        it("goes back on the player's pick once it runs out", function()
            local h = holy()
                h:joinRaid({ { class = "PRIEST" }, { class = "WARRIOR", mainTank = true } })
            h:settle()
            cast(h, "raid2")
            h:remove("Oath of Light", "raid2")
            assert.equal("Oath of Light", h:shown())
            assert.equal("raid2", h:target())
        end)

        it("is refreshed in its last minute", function()
            local h = holy()
            h:joinParty({ { class = "WARRIOR" } })
            cast(h, "party1", { remaining = 90 })
            assert.is_nil(h:shown())
            cast(h, "party1", { remaining = 50 })
            assert.equal("Oath of Light", h:shown())
            assert.equal("party1", h:target())
        end)

        it("isn't moved while its target is dead", function()
            local h = holy()
                h:joinRaid({ { class = "PRIEST" }, { class = "WARRIOR", mainTank = true } })
            h:settle()
            cast(h, "raid2")
            h:remove("Oath of Light", "raid2")
            h:setMember("raid2", { dead = true })
            h:refresh()
            assert.is_nil(h:shown())
        end)

        it("goes to the main tank once its target leaves", function()
            local h = holy()
                h:joinRaid({ { class = "PRIEST", name = "Pia Priest" }, { class = "WARRIOR", mainTank = true } })
            h:settle()
            cast(h, "raid2")
            h:joinRaid({ { class = "WARRIOR", mainTank = true } })
            h:settle()
            assert.equal("Oath of Light", h:shown())
            assert.equal("raid2", h:target())
        end)

        it("doesn't count another Paladin's Oath", function()
            local h = holy()
                h:joinRaid({ { class = "WARRIOR", mainTank = true } })
            h:settle()
            cast(h, "raid2", { fromPlayer = false, source = "raid3" })
            assert.equal("Oath of Light", h:shown())
        end)

        it("waits until its target is back in range", function()
            local h = holy()
                h:joinRaid({ { class = "WARRIOR", mainTank = true, inRange = false } })
            h:settle()
            assert.is_nil(h:shown())
            h:setMember("raid2", { inRange = true })
            assert.equal("Oath of Light", h:shown())
        end)
    end)
end)
