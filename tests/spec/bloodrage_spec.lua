local Addon = require("helpers.load_addon")

local CHAINED = "/cast Bloodrage\n/cast [target=player]Battle Shout"

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

    it("casts Bloodrage before Battle Shout when out of rage", function()
        assert.equal(CHAINED, h.button:GetAttribute("macrotext1"))
        assert.is_true(h.button:IsShown())
    end)

    it("shows the Battle Shout icon", function()
        assert.equal(h.state:iconOf("Battle Shout"), h.button:GetNormalTexture())
    end)

    it("keeps the button in combat so the next press casts Battle Shout", function()
        h:enterCombat()
        assert.is_true(h.button:IsShown())
        assert.equal(CHAINED, h.button:GetAttribute("macrotext1"))
    end)

    it("keeps the macro while Bloodrage is active, before the rage arrives", function()
        h.state.cooldowns["Bloodrage"] = 60
        h:give("Bloodrage", { duration = 10 })
        assert.equal(CHAINED, h.button:GetAttribute("macrotext1"))
    end)

    it("casts plain Battle Shout once there is rage", function()
        h.state.unusable["Battle Shout"] = nil
        h:refresh()
        assert.equal("Battle Shout", h:shown())
    end)

    it("hides the button again after Battle Shout lands and combat ends", function()
        h:enterCombat()
        h.state.unusable["Battle Shout"] = nil
        h.state:giveAura("Battle Shout")
        h:leaveCombat()
        assert.is_nil(h:shown())
    end)

    it("skips Battle Shout when out of rage with Bloodrage on cooldown", function()
        h.state.cooldowns["Bloodrage"] = 60
        h:refresh()
        assert.is_nil(h:shown())
    end)

    it("hides the button in combat when the macro has no Bloodrage", function()
        h.state.unusable["Battle Shout"] = nil
        h:refresh()
        h:enterCombat()
        assert.is_false(h.button:IsShown())
    end)

    it("skips Battle Shout without Bloodrage learned", function()
        h.state:unlearn("Bloodrage")
        h:refresh()
        assert.is_nil(h:shown())
    end)
end)
