local Addon = require("helpers.load_addon")

local function paladin(known)
    return Addon.load({
        class = "PALADIN",
        known = known or { "Blessing of Might", "Blessing of Wisdom", "Greater Blessing of Wisdom" },
    })
end

describe("Greater Blessings", function()
    describe("in the test harness", function()
        it("land on every raid member of the target's class, across subgroups", function()
            local h = paladin()
            h:joinRaid({
                { class = "PRIEST", subgroup = 1 },
                { class = "PRIEST", subgroup = 3 },
                { class = "MAGE", subgroup = 1 },
                { class = "PRIEST", subgroup = 5, dead = true },
                { class = "PRIEST", subgroup = 2, inRange = false },
            })
            assert.same({ "raid2", "raid3" }, h:landsOn("Greater Blessing of Wisdom", "raid2"))
        end)

        it("include the player when the class is the player's", function()
            local h = paladin()
            h:joinRaid({ { class = "PALADIN", subgroup = 4 }, { class = "PRIEST" } })
            assert.same({ "player", "raid2" }, h:landsOn("Greater Blessing of Wisdom", "raid2"))
        end)

        it("leave other group versions on the subgroup", function()
            local h = paladin()
            h:joinRaid({ { class = "PRIEST", subgroup = 1 }, { class = "PRIEST", subgroup = 2 } })
            assert.same(1, #h:landsOn("Arcane Brilliance", "raid3"))
        end)
    end)

    describe("reagents", function()
        it("need Symbol of Kings", function()
            local h = paladin()
            assert.is_nil(h.ns.CastableGroupVersion("Blessing of Wisdom"))
            h:bag("Symbol of Kings")
            assert.equal("Greater Blessing of Wisdom", h.ns.CastableGroupVersion("Blessing of Wisdom"))
        end)

        it("aren't needed with Reagent Economy", function()
            local h = paladin()
            h:learn("Reagent Economy")
            assert.equal("Greater Blessing of Wisdom", h.ns.CastableGroupVersion("Blessing of Wisdom"))
        end)

        it("don't help before the Greater Blessing is learned", function()
            local h = paladin()
            h:bag("Symbol of Kings")
            assert.is_nil(h.ns.CastableGroupVersion("Blessing of Might"))
        end)
    end)
end)
