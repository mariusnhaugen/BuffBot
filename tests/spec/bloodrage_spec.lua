local Addon = require("helpers.load_addon")

local CHAINED = "/cast [nocombat] Bloodrage\n/cast [target=player]Battle Shout"

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

    it("casts Bloodrage before Battle Shout", function()
        assert.equal(CHAINED, h.button:GetAttribute("macrotext1"))
        assert.is_true(h.button:IsShown())
    end)

    it("shows the Battle Shout icon", function()
        assert.equal(h.state:iconOf("Battle Shout"), h.button:GetNormalTexture():GetTexture())
    end)

    it("keeps the Bloodrage macro with enough rage", function()
        h.state.unusable["Battle Shout"] = nil
        h:refresh()
        assert.equal(CHAINED, h.button:GetAttribute("macrotext1"))
    end)

    it("hides the button in combat like any other buff", function()
        h:enterCombat()
        assert.is_false(h.button:IsShown())
    end)

    it("is not tinted, since Bloodrage makes the rage", function()
        assert.same({ 1.0, 1.0, 1.0 }, { h.button:GetNormalTexture():GetVertexColor() })
    end)

    it("shows plain Battle Shout, tinted blue, without Bloodrage learned", function()
        h.state:unlearn("Bloodrage")
        h:refresh()
        assert.equal("Battle Shout", h:shown())
        assert.same({ 0.5, 0.5, 1.0 }, { h.button:GetNormalTexture():GetVertexColor() })
    end)
end)
