local Addon = require("helpers.load_addon")

describe("per-class buff priority (vanilla spells)", function()
    it("DRUID: Omen of Clarity, Mark of the Wild, Thorns", function()
        local h = Addon.load({ class = "DRUID", known = { "Omen of Clarity", "Mark of the Wild", "Thorns" } })
        assert.same({ "Omen of Clarity", "Mark of the Wild", "Thorns" }, h:buffUp())
    end)

    it("DRUID: unknown spells are left out", function()
        local h = Addon.load({ class = "DRUID", known = { "Mark of the Wild" } })
        assert.same({ "Mark of the Wild" }, h:buffUp())
    end)

    it("HUNTER: Trueshot Aura, then Aspect of the Hawk", function()
        local h = Addon.load({ class = "HUNTER", known = { "Trueshot Aura", "Aspect of the Hawk" } })
        assert.same({ "Trueshot Aura", "Aspect of the Hawk" }, h:buffUp())
    end)

    describe("MAGE armor pick", function()
        local all = { "Frost Armor", "Ice Armor", "Mage Armor", "Arcane Intellect", "Dampen Magic" }

        it("prefers Ice Armor outside a raid", function()
            local h = Addon.load({ class = "MAGE", known = all })
            assert.same({ "Ice Armor", "Arcane Intellect", "Dampen Magic" }, h:buffUp())
        end)

        it("prefers Mage Armor in a raid", function()
            local h = Addon.load({ class = "MAGE", known = all, raid = true })
            assert.same({ "Mage Armor", "Arcane Intellect", "Dampen Magic" }, h:buffUp())
        end)

        it("switches to Mage Armor on joining a raid", function()
            local h = Addon.load({ class = "MAGE", known = all })
            assert.equal("Ice Armor", h:shown())
            h:joinRaid()
            assert.equal("Mage Armor", h:shown())
        end)

        it("switches back to Ice Armor on leaving the group", function()
            local h = Addon.load({ class = "MAGE", known = all, raid = true })
            h:leaveGroup()
            assert.equal("Ice Armor", h:shown())
        end)

        it("falls back to Frost Armor at low level", function()
            local h = Addon.load({ class = "MAGE", known = { "Frost Armor", "Arcane Intellect" } })
            assert.same({ "Frost Armor", "Arcane Intellect" }, h:buffUp())
        end)

        it("recommends no armor when only Mage Armor is known outside a raid", function()
            local h = Addon.load({ class = "MAGE", known = { "Mage Armor", "Arcane Intellect" } })
            assert.same({ "Arcane Intellect" }, h:buffUp())
        end)
    end)

    describe("PALADIN", function()
        it("Devotion Aura, then Blessing of Might", function()
            local h = Addon.load({ class = "PALADIN", known = { "Devotion Aura", "Blessing of Might" } })
            assert.same({ "Devotion Aura", "Blessing of Might" }, h:buffUp())
        end)

        it("prefers Sanctity Aura over Devotion Aura", function()
            local h = Addon.load({ class = "PALADIN", known = { "Devotion Aura", "Sanctity Aura" } })
            assert.same({ "Sanctity Aura" }, h:buffUp())
        end)

        it("recommends Blessing of Wisdom when WISDOM_SELF is on", function()
            local h = Addon.load({
                class = "PALADIN",
                known = { "Blessing of Might", "Blessing of Wisdom" },
                config = { WISDOM_SELF = true },
            })
            assert.same({ "Blessing of Wisdom" }, h:buffUp())
        end)

        pending("recommends Retribution Aura when it is the only aura known (known bug: missing from spellIDTable)")
    end)

    it("PRIEST: Fortitude, Shadowform, Divine Spirit, Inner Fire", function()
        local h = Addon.load({
            class = "PRIEST",
            known = { "Power Word: Fortitude", "Shadowform", "Divine Spirit", "Inner Fire" },
        })
        assert.same({ "Power Word: Fortitude", "Shadowform", "Divine Spirit", "Inner Fire" }, h:buffUp())
    end)

    it("ROGUE: nothing to cast, button hidden", function()
        local h = Addon.load({ class = "ROGUE" })
        assert.is_nil(h:shown())
        assert.is_false(h.button:IsShown())
    end)

    it("SHAMAN: Lightning Shield", function()
        local h = Addon.load({ class = "SHAMAN", known = { "Lightning Shield" } })
        assert.same({ "Lightning Shield" }, h:buffUp())
    end)

    describe("WARLOCK armor pick", function()
        it("prefers Demon Armor over Demon Skin", function()
            local h = Addon.load({ class = "WARLOCK", known = { "Demon Skin", "Demon Armor" } })
            assert.same({ "Demon Armor" }, h:buffUp())
        end)

        it("falls back to Demon Skin", function()
            local h = Addon.load({ class = "WARLOCK", known = { "Demon Skin" } })
            assert.same({ "Demon Skin" }, h:buffUp())
        end)
    end)

    it("WARRIOR: Battle Shout", function()
        local h = Addon.load({ class = "WARRIOR", known = { "Battle Shout" } })
        assert.same({ "Battle Shout" }, h:buffUp())
    end)

    it("learning a spell adds it to the list", function()
        local h = Addon.load({ class = "PRIEST", known = { "Inner Fire" } })
        h:give("Inner Fire")
        assert.is_nil(h:shown())
        h:learn("Power Word: Fortitude")
        assert.equal("Power Word: Fortitude", h:shown())
    end)
end)
