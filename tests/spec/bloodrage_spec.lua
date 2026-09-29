local Addon = require("helpers.load_addon")

describe("Warrior Bloodrage option", function()
    local h

    before_each(function()
        h = Addon.load({
            class = "WARRIOR",
            known = { "Battle Shout", "Bloodrage" },
            config = { BLOODRAGE = true },
        })
        h.state.unusable["Battle Shout"] = true
        h:refresh()
    end)

    it("inserts Bloodrage before Battle Shout when out of rage", function()
        assert.same({ "Bloodrage", "Battle Shout" }, h.ns.classBuffList)
    end)

    it("shows Bloodrage once it has been inserted", function()
        h:refresh()
        assert.equal("Bloodrage", h:shown())
    end)

    it("removes Bloodrage and goes back to Battle Shout after casting it", function()
        h:refresh()
        h:cast("Bloodrage")
        assert.same({ "Battle Shout" }, h.ns.classBuffList)
        assert.equal("Battle Shout", h:shown())
        assert.is_true(h.ns.BLOODRAGE_LOCKED)
    end)

    it("does not re-insert Bloodrage while locked", function()
        h:refresh()
        h:cast("Bloodrage")
        h:refresh()
        assert.same({ "Battle Shout" }, h.ns.classBuffList)
    end)

    it("unlocks after Battle Shout is cast", function()
        h:refresh()
        h:cast("Bloodrage")
        h.state.unusable["Battle Shout"] = nil
        h.state:giveAura("Battle Shout")
        h:cast("Battle Shout")
        assert.is_false(h.ns.BLOODRAGE_LOCKED)
        assert.is_nil(h:shown())
    end)

    pending("handles Battle Shout dropping while Bloodrage is on cooldown (known bug)")
end)
