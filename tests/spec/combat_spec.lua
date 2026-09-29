local Addon = require("helpers.load_addon")

describe("combat", function()
    local h

    before_each(function()
        h = Addon.load({ class = "MAGE", known = { "Arcane Intellect", "Dampen Magic" } })
    end)

    it("hides the button on entering combat", function()
        assert.equal("Arcane Intellect", h:shown())
        h:enterCombat()
        assert.is_false(h.button:IsShown())
    end)

    it("finds nothing to cast in combat", function()
        h:enterCombat()
        assert.equal("done", h.ns.FindNextBuffInList())
    end)

    it("does not touch the secure button in combat", function()
        h:enterCombat()
        h.ns.UpdateMacro("Dampen Magic", "player")
        assert.equal("/cast [target=player]Arcane Intellect", h.button:GetAttribute("macrotext1"))
        assert.is_false(h.button:IsShown())
    end)

    it("stays hidden when auras change in combat", function()
        h:enterCombat()
        h:give("Arcane Intellect")
        h:remove("Arcane Intellect")
        assert.is_false(h.button:IsShown())
    end)

    it("re-checks on leaving combat", function()
        h:enterCombat()
        h.state:giveAura("Arcane Intellect")
        h:leaveCombat()
        assert.equal("Dampen Magic", h:shown())
    end)

    it("stays hidden after combat when fully buffed", function()
        h:enterCombat()
        h.state:giveAura("Arcane Intellect")
        h.state:giveAura("Dampen Magic")
        h:leaveCombat()
        assert.is_nil(h:shown())
    end)
end)
