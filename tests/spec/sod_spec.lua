-- Season of Discovery / TBC-only behaviour. This whole file is deleted when
-- the Forever port strips those spells.
local Addon = require("helpers.load_addon")

describe("SoD spells", function()
    it("HUNTER: Heart of the Lion comes first", function()
        local h = Addon.load({
            class = "HUNTER",
            known = { "Heart of the Lion", "Trueshot Aura", "Aspect of the Hawk" },
        })
        assert.same({ "Heart of the Lion", "Trueshot Aura", "Aspect of the Hawk" }, h:buffUp())
    end)

    it("HUNTER: Aspect of the Viper counts as an aspect", function()
        local h = Addon.load({ class = "HUNTER", known = { "Aspect of the Hawk" } })
        h:give("Aspect of the Viper")
        assert.is_nil(h:shown())
    end)

    it("MAGE: Molten Armor beats everything", function()
        local h = Addon.load({
            class = "MAGE",
            known = { "Molten Armor", "Mage Armor", "Ice Armor" },
            raid = true,
        })
        assert.equal("Molten Armor", h:shown())
    end)

    it("WARLOCK: Fel Armor in a raid", function()
        local h = Addon.load({ class = "WARLOCK", known = { "Fel Armor", "Demon Armor" }, raid = true })
        assert.equal("Fel Armor", h:shown())
    end)

    it("WARLOCK: Demon Armor over Fel Armor outside a raid", function()
        local h = Addon.load({ class = "WARLOCK", known = { "Fel Armor", "Demon Armor" } })
        assert.equal("Demon Armor", h:shown())
    end)

    it("WARLOCK: Grimoire of Synergy needs an active pet", function()
        local h = Addon.load({ class = "WARLOCK", known = { "Grimoire of Synergy" } })
        assert.is_nil(h:shown())
        h.state.pet = true
        h:refresh()
        assert.equal("Grimoire of Synergy", h:shown())
    end)

    it("WARRIOR: Valor of Azeroth, Commanding Shout, Battle Shout", function()
        local h = Addon.load({
            class = "WARRIOR",
            known = { "Valor of Azeroth", "Commanding Shout", "Battle Shout" },
        })
        assert.same({ "Valor of Azeroth", "Commanding Shout", "Battle Shout" }, h:buffUp())
    end)

    it("WARRIOR: Rallying Cry covers Valor of Azeroth", function()
        local h = Addon.load({ class = "WARRIOR", known = { "Valor of Azeroth" } })
        h:give("Rallying Cry of the Dragonslayer")
        assert.is_nil(h:shown())
    end)

    it("WARRIOR: Blood Pact covers Commanding Shout", function()
        local h = Addon.load({ class = "WARRIOR", known = { "Commanding Shout" } })
        h:give("Blood Pact")
        assert.is_nil(h:shown())
    end)
end)
