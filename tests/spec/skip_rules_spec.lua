local Addon = require("helpers.load_addon")

describe("skip rules", function()
    it("Gift of the Wild covers Mark of the Wild", function()
        local h = Addon.load({ class = "DRUID", known = { "Mark of the Wild", "Thorns" } })
        h:give("Gift of the Wild")
        assert.same({ "Thorns" }, h:buffUp())
    end)

    it("Prayer of Fortitude covers Power Word: Fortitude", function()
        local h = Addon.load({ class = "PRIEST", known = { "Power Word: Fortitude", "Inner Fire" } })
        h:give("Prayer of Fortitude")
        assert.same({ "Inner Fire" }, h:buffUp())
    end)

    it("Arcane Brilliance covers Arcane Intellect", function()
        local h = Addon.load({ class = "MAGE", known = { "Arcane Intellect", "Dampen Magic" } })
        h:give("Arcane Brilliance")
        assert.same({ "Dampen Magic" }, h:buffUp())
    end)

    it("Prayer of Spirit covers Divine Spirit", function()
        local h = Addon.load({ class = "PRIEST", known = { "Divine Spirit", "Inner Fire" } })
        h:give("Prayer of Spirit")
        assert.same({ "Inner Fire" }, h:buffUp())
    end)

    it("Greater Blessing of Might covers Blessing of Might", function()
        local h = Addon.load({ class = "PALADIN", known = { "Blessing of Might" } })
        h:give("Greater Blessing of Might")
        assert.same({}, h:buffUp())
    end)

    it("Greater Blessing of Wisdom covers Blessing of Wisdom", function()
        local h = Addon.load({
            class = "PALADIN",
            known = { "Blessing of Wisdom" },
            config = { PALADIN_BLESSING = "Blessing of Wisdom" },
        })
        h:give("Greater Blessing of Wisdom")
        assert.same({}, h:buffUp())
    end)

    it("an expiring group version no longer covers the buff", function()
        local h = Addon.load({ class = "MAGE", known = { "Arcane Intellect" } })
        h:give("Arcane Brilliance", { duration = 3600, remaining = 200 })
        assert.equal("Arcane Intellect", h:shown())
    end)

    it("IGNORE_THORNS skips Thorns", function()
        local h = Addon.load({
            class = "DRUID",
            known = { "Mark of the Wild", "Thorns" },
            config = { IGNORE_THORNS = true },
        })
        assert.same({ "Mark of the Wild" }, h:buffUp())
    end)

    it("IGNORE_DAMPEN skips Dampen Magic", function()
        local h = Addon.load({
            class = "MAGE",
            known = { "Arcane Intellect", "Dampen Magic" },
            config = { IGNORE_DAMPEN = true },
        })
        assert.same({ "Arcane Intellect" }, h:buffUp())
    end)

    describe("unique armors and auras", function()
        it("any active Mage armor satisfies the armor slot", function()
            local h = Addon.load({ class = "MAGE", known = { "Frost Armor", "Ice Armor", "Arcane Intellect" } })
            h:give("Frost Armor")
            assert.same({ "Arcane Intellect" }, h:buffUp())
        end)

        it("STRICT_ARMOR requires the recommended armor", function()
            local h = Addon.load({
                class = "MAGE",
                known = { "Frost Armor", "Ice Armor", "Arcane Intellect" },
                config = { STRICT_ARMOR = true },
            })
            h:give("Frost Armor")
            assert.same({ "Ice Armor", "Arcane Intellect" }, h:buffUp())
        end)

        it("any active Warlock armor satisfies the armor slot", function()
            local h = Addon.load({ class = "WARLOCK", known = { "Demon Skin", "Demon Armor" } })
            h:give("Demon Skin")
            assert.same({}, h:buffUp())
        end)

        it("any active Paladin aura satisfies the aura slot", function()
            local h = Addon.load({ class = "PALADIN", known = { "Devotion Aura", "Blessing of Might" } })
            h:give("Concentration Aura")
            assert.same({ "Blessing of Might" }, h:buffUp())
        end)

        it("another Paladin's aura does not satisfy the aura slot", function()
            local h = Addon.load({ class = "PALADIN", known = { "Devotion Aura", "Blessing of Might" } })
            h:give("Concentration Aura", { fromPlayer = false })
            assert.same({ "Devotion Aura", "Blessing of Might" }, h:buffUp())
        end)

        it("another Paladin's copy of the recommended aura does not count", function()
            local h = Addon.load({ class = "PALADIN", known = { "Devotion Aura" } })
            h:give("Devotion Aura", { fromPlayer = false })
            assert.equal("Devotion Aura", h:shown())
        end)

        it("another Paladin's blessing still counts", function()
            local h = Addon.load({ class = "PALADIN", known = { "Blessing of Might" } })
            h:give("Blessing of Might", { fromPlayer = false })
            assert.is_nil(h:shown())
        end)

        it("any active Hunter aspect satisfies Aspect of the Hawk", function()
            local h = Addon.load({ class = "HUNTER", known = { "Aspect of the Hawk" } })
            h:give("Aspect of the Monkey")
            assert.same({}, h:buffUp())
        end)
    end)

    describe("Hunter Cheetah reminder", function()
        it("is on by default: Cheetah does not count, Hawk is shown", function()
            local h = Addon.load({ class = "HUNTER", known = { "Aspect of the Hawk" } })
            h:give("Aspect of the Cheetah")
            assert.equal("Aspect of the Hawk", h:shown())
        end)

        it("Pack does not count either", function()
            local h = Addon.load({ class = "HUNTER", known = { "Aspect of the Hawk" } })
            h:give("Aspect of the Pack")
            assert.equal("Aspect of the Hawk", h:shown())
        end)

        it("when off, Cheetah counts as an aspect", function()
            local h = Addon.load({
                class = "HUNTER",
                known = { "Aspect of the Hawk" },
                config = { CHEETAH_REMINDER = false },
            })
            h:give("Aspect of the Cheetah")
            assert.is_nil(h:shown())
        end)

        it("repeated rebuilds do not grow the aspect list", function()
            local h = Addon.load({
                class = "HUNTER",
                known = { "Aspect of the Hawk" },
                config = { CHEETAH_REMINDER = false },
            })
            h:fire("SPELLS_CHANGED")
            local size = #h.ns.uniqueBuffs
            for _ = 1, 3 do h:fire("SPELLS_CHANGED") end
            assert.equal(size, #h.ns.uniqueBuffs)
        end)

        it("toggling the setting on and off round-trips", function()
            local h = Addon.load({ class = "HUNTER", known = { "Aspect of the Hawk" } })
            local sizeOn = #h.ns.uniqueBuffs
            h:setting("CHEETAH_REMINDER", false)
            local sizeOff = #h.ns.uniqueBuffs
            h:setting("CHEETAH_REMINDER", true)
            assert.equal(sizeOn + 2, sizeOff)
            assert.equal(sizeOn, #h.ns.uniqueBuffs)
        end)
    end)

    it("Battle Shout without rage still shows, tinted blue, when BLOODRAGE is off", function()
        local h = Addon.load({ class = "WARRIOR", known = { "Battle Shout", "Bloodrage" } })
        h.state.unusable["Battle Shout"] = true
        h:refresh()
        assert.equal("Battle Shout", h:shown())
        assert.same({ 0.5, 0.5, 1.0 }, { h.button:GetNormalTexture():GetVertexColor() })
    end)

    it("Battle Shout with rage is not tinted", function()
        local h = Addon.load({ class = "WARRIOR", known = { "Battle Shout" } })
        assert.same({ 1.0, 1.0, 1.0 }, { h.button:GetNormalTexture():GetVertexColor() })
    end)

    it("the tint follows rage without a re-check", function()
        local h = Addon.load({ class = "WARRIOR", known = { "Battle Shout" } })
        h:setOutOfPower("Battle Shout", true)
        assert.same({ 0.5, 0.5, 1.0 }, { h.button:GetNormalTexture():GetVertexColor() })
        assert.equal(0.6, h.button:GetNormalTexture():GetAlpha())
        h:setOutOfPower("Battle Shout", false)
        assert.same({ 1.0, 1.0, 1.0 }, { h.button:GetNormalTexture():GetVertexColor() })
        assert.equal(1, h.button:GetNormalTexture():GetAlpha())
    end)

    it("a hidden icon stays hidden when it runs out of rage", function()
        local h = Addon.load({ class = "WARRIOR", known = { "Battle Shout" }, config = { HIDE_ICON = true } })
        h:setOutOfPower("Battle Shout", true)
        assert.equal(0, h.button:GetNormalTexture():GetAlpha())
        h:setting("HIDE_ICON", false)
        assert.equal(0.6, h.button:GetNormalTexture():GetAlpha())
    end)
end)
