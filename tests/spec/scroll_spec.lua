local Addon = require("helpers.load_addon")

describe("scroll buffs", function()
    local AI_RANK_2, AI_RANK_3, AI_RANK_4 = 1460, 1461, 10156
    local INT_SCROLL_I, INT_SCROLL_II, INT_SCROLL_III, INT_SCROLL_IV = 8096, 8097, 8098, 12176
    local FORT_RANK_2, FORT_RANK_3 = 1244, 1245
    local STAM_SCROLL_I, STAM_SCROLL_II, STAM_SCROLL_III, STAM_SCROLL_IV = 8099, 8100, 8101, 12178

    local function mage(rank)
        return Addon.load({ class = "MAGE", known = { "Arcane Intellect" }, ranks = { ["Arcane Intellect"] = rank } })
    end

    local function priest(rank)
        return Addon.load({
            class = "PRIEST",
            known = { "Power Word: Fortitude" },
            ranks = { ["Power Word: Fortitude"] = rank },
        })
    end

    describe("Arcane Intellect", function()
        it("is skipped under a stronger scroll", function()
            local h = mage(AI_RANK_2)
            h:give("Intellect", { spellId = INT_SCROLL_II })
            assert.is_nil(h:shown())
        end)

        it("is offered over a weaker scroll", function()
            local h = mage(AI_RANK_2)
            h:give("Intellect", { spellId = INT_SCROLL_I })
            assert.equal("Arcane Intellect", h:shown())
        end)

        it("comes back when the scroll drops", function()
            local h = mage(AI_RANK_2)
            h:give("Intellect", { spellId = INT_SCROLL_IV })
            assert.is_nil(h:shown())
            h:remove("Intellect")
            assert.equal("Arcane Intellect", h:shown())
        end)

        it("loses to the best scroll by a point at rank 3", function()
            local h = mage(AI_RANK_3)
            h:give("Intellect", { spellId = INT_SCROLL_III })
            assert.equal("Arcane Intellect", h:shown())
            h:give("Intellect", { spellId = INT_SCROLL_IV })
            assert.is_nil(h:shown())
        end)

        it("is offered over every scroll from rank 4", function()
            local h = mage(AI_RANK_4)
            h:give("Intellect", { spellId = INT_SCROLL_IV })
            assert.equal("Arcane Intellect", h:shown())
        end)
    end)

    describe("Power Word: Fortitude", function()
        it("loses to a stronger scroll at a low rank", function()
            local h = priest(FORT_RANK_2)
            h:give("Stamina", { spellId = STAM_SCROLL_III })
            assert.is_nil(h:shown())
            h:give("Stamina", { spellId = STAM_SCROLL_II })
            assert.equal("Power Word: Fortitude", h:shown())
        end)

        it("is offered over every scroll from rank 3", function()
            local h = priest(FORT_RANK_3)
            h:give("Stamina", { spellId = STAM_SCROLL_IV })
            assert.equal("Power Word: Fortitude", h:shown())
        end)

        it("is offered on a tie with rank 1", function()
            local h = priest()
            h:give("Stamina", { spellId = STAM_SCROLL_I })
            assert.equal("Power Word: Fortitude", h:shown())
        end)
    end)

    describe("unknown amounts", function()
        it("offers the buff when the aura isn't a scroll in the table", function()
            local h = mage(AI_RANK_2)
            h:give("Intellect", { spellId = 99999 })
            assert.equal("Arcane Intellect", h:shown())
        end)

        it("offers the buff when the rank isn't in the table", function()
            local h = mage(99999)
            h:give("Intellect", { spellId = INT_SCROLL_IV })
            assert.equal("Arcane Intellect", h:shown())
        end)
    end)

    describe("in a party", function()
        it("skips only the member with the stronger scroll", function()
            local h = mage(AI_RANK_2)
            h:joinParty({ { class = "PRIEST" }, { class = "MAGE" } })
            h:give("Arcane Intellect")
            h:give("Intellect", { unit = "party1", spellId = INT_SCROLL_III })
            assert.equal("/cast [target=party2]Arcane Intellect", h.button:GetAttribute("macrotext1"))
        end)

        it("offers the buff once the member's scroll drops", function()
            local h = mage(AI_RANK_2)
            h:joinParty({ { class = "PRIEST" } })
            h:give("Arcane Intellect")
            h:give("Intellect", { unit = "party1", spellId = INT_SCROLL_III })
            assert.is_nil(h:shown())
            h:remove("Intellect", "party1")
            assert.equal("/cast [target=party1]Arcane Intellect", h.button:GetAttribute("macrotext1"))
        end)

        it("doesn't report that member as out of range", function()
            local h = mage(AI_RANK_2)
            h:joinParty({ { class = "PRIEST", inRange = false } })
            h:give("Arcane Intellect")
            h:give("Intellect", { unit = "party1", spellId = INT_SCROLL_III })
            h:slash("status")
            assert.is_false(h:printed("Someone else missing a buff is out of range."))
        end)
    end)

    it("names the skip in /bb status", function()
        local h = mage(AI_RANK_2)
        h:give("Intellect", { spellId = INT_SCROLL_II })
        h:slash("status")
        assert.is_true(h:printed("Skipped: Arcane Intellect on you (stronger scroll)"))
    end)

    it("leaves other buffs alone", function()
        local h = Addon.load({ class = "PRIEST", known = { "Divine Spirit" } })
        h:give("Stamina", { spellId = STAM_SCROLL_IV })
        assert.equal("Divine Spirit", h:shown())
    end)
end)
