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
        assert.equal(h.state:iconOf("Battle Shout"), h.button:GetNormalTexture())
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

    it("skips Battle Shout without Bloodrage learned", function()
        h.state:unlearn("Bloodrage")
        h:refresh()
        assert.is_nil(h:shown())
    end)
end)
