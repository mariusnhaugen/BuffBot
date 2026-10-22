local Addon = require("helpers.load_addon")

describe("group buffing", function()
    local function mage(opts)
        opts = opts or {}
        opts.class = "MAGE"
        opts.known = opts.known or { "Arcane Intellect" }
        return Addon.load(opts)
    end

    local function priest()
        return Addon.load({ class = "PRIEST", known = { "Power Word: Fortitude", "Divine Spirit" } })
    end

    describe("in a party", function()
        it("buffs the player, then each member in order", function()
            local h = mage()
            h:joinParty({ { class = "PRIEST" }, { class = "MAGE" } })
            assert.same({ "Arcane Intellect", "Arcane Intellect > party1", "Arcane Intellect > party2" }, h:buffUp())
        end)

        it("casts with the member as the target", function()
            local h = mage()
            h:joinParty({ { class = "PRIEST" } })
            h:give("Arcane Intellect")
            assert.equal("/cast [target=party1]Arcane Intellect", h.button:GetAttribute("macrotext1"))
        end)

        it("moves on once the member has it", function()
            local h = mage()
            h:joinParty({ { class = "PRIEST" } })
            h:give("Arcane Intellect")
            h:give("Arcane Intellect", { unit = "party1" })
            assert.is_nil(h:shown())
        end)

        it("comes back when a member's buff drops", function()
            local h = mage()
            h:joinParty({ { class = "PRIEST" } })
            h:buffUp()
            h:remove("Arcane Intellect", "party1")
            assert.equal("party1", h:target())
        end)

        it("counts a member's expiring buff as missing", function()
            local h = mage()
            h:joinParty({ { class = "PRIEST" } })
            h:give("Arcane Intellect")
            h:give("Arcane Intellect", { unit = "party1", remaining = 60 })
            assert.equal("party1", h:target())
        end)

        it("puts one buff on everyone before the next", function()
            local h = priest()
            h:joinParty({ { class = "MAGE" } })
            assert.same({ "Power Word: Fortitude", "Power Word: Fortitude > party1", "Divine Spirit",
                "Divine Spirit > party1" }, h:buffUp())
        end)

        it("is player-only with group buffing turned off", function()
            local h = mage({ config = { GROUP_BUFFING = false } })
            h:joinParty({ { class = "PRIEST" } })
            assert.same({ "Arcane Intellect" }, h:buffUp())
        end)

        it("is player-only after leaving the group", function()
            local h = mage()
            h:joinParty({ { class = "PRIEST" } })
            h:leaveGroup()
            assert.same({ "Arcane Intellect" }, h:buffUp())
        end)
    end)

    describe("skipping members", function()
        it("skips dead, offline and hidden members", function()
            local h = mage()
            h:joinParty({ { class = "PRIEST", dead = true }, { class = "MAGE", offline = true },
                { class = "DRUID", visible = false }, { class = "HUNTER" } })
            assert.same({ "Arcane Intellect", "Arcane Intellect > party4" }, h:buffUp())
        end)

        it("skips a member out of range, and picks them up once in range", function()
            local h = mage()
            h:joinParty({ { class = "PRIEST", inRange = false } })
            assert.same({ "Arcane Intellect" }, h:buffUp())
            h:setMember("party1", { inRange = true })
            assert.equal("party1", h:target())
        end)

        it("stops polling for range in combat", function()
            local h = mage()
            h:joinParty({ { class = "PRIEST", inRange = false } })
            h:buffUp()
            h:enterCombat()
            h:setMember("party1", { inRange = true })
            assert.is_false(h.button:IsShown())
        end)

        it("never casts Arcane Intellect on Warriors or Rogues", function()
            local h = mage()
            h:joinParty({ { class = "WARRIOR" }, { class = "ROGUE" }, { class = "PALADIN" } })
            assert.same({ "Arcane Intellect", "Arcane Intellect > party3" }, h:buffUp())
        end)

        it("gives Warriors Fortitude but not Divine Spirit", function()
            local h = priest()
            h:joinParty({ { class = "WARRIOR" } })
            assert.same({ "Power Word: Fortitude", "Power Word: Fortitude > party1", "Divine Spirit" }, h:buffUp())
        end)

        it("doesn't check range for a class it skips", function()
            local h = mage()
            h:joinParty({ { class = "WARRIOR" } })
            local ranged = {}
            local isSpellInRange = h.env.C_Spell.IsSpellInRange
            h.env.C_Spell.IsSpellInRange = function(spell, unit)
                ranged[unit] = true
                return isSpellInRange(spell, unit)
            end
            h:refresh()
            assert.is_nil(ranged.party1)
        end)

        it("counts a member's group version as covering the buff", function()
            local h = mage()
            h:joinParty({ { class = "PRIEST" } })
            h:give("Arcane Intellect")
            h:give("Arcane Brilliance", { unit = "party1" })
            assert.is_nil(h:shown())
        end)
    end)

    describe("self-only buffs", function()
        it("keeps Dampen Magic on the player", function()
            local h = mage({ known = { "Arcane Intellect", "Dampen Magic" } })
            h:joinParty({ { class = "PRIEST" } })
            assert.same({ "Arcane Intellect", "Arcane Intellect > party1", "Dampen Magic" }, h:buffUp())
        end)

        it("keeps Thorns on the player", function()
            local h = Addon.load({ class = "DRUID", known = { "Mark of the Wild", "Thorns" } })
            h:joinParty({ { class = "WARRIOR" } })
            assert.same({ "Mark of the Wild", "Mark of the Wild > party1", "Thorns" }, h:buffUp())
        end)

        it("keeps Paladin blessings on the player", function()
            local h = Addon.load({ class = "PALADIN", known = { "Blessing of Might" } })
            h:joinParty({ { class = "WARRIOR" } })
            assert.same({ "Blessing of Might" }, h:buffUp())
        end)
    end)

    describe("group versions", function()
        local function brillianceMage(opts)
            opts = opts or {}
            opts.known = { "Arcane Intellect", "Arcane Brilliance" }
            return mage(opts)
        end

        it("casts single-target without the reagent", function()
            local h = brillianceMage()
            h:joinParty({ { class = "PRIEST" }, { class = "MAGE" } })
            assert.same({ "Arcane Intellect", "Arcane Intellect > party1", "Arcane Intellect > party2" }, h:buffUp())
        end)

        it("casts the group version with the reagent when two or more are missing", function()
            local h = brillianceMage()
            h:bag("Arcane Powder")
            h:joinParty({ { class = "PRIEST" }, { class = "MAGE" } })
            assert.equal("player", h:target())
            assert.same({ "Arcane Brilliance" }, h:buffUp())
        end)

        it("casts the group version with Reagent Economy and no reagent", function()
            local h = brillianceMage()
            h:learn("Reagent Economy")
            h:joinParty({ { class = "PRIEST" } })
            assert.same({ "Arcane Brilliance" }, h:buffUp())
        end)

        it("targets the first member missing it", function()
            local h = brillianceMage()
            h:bag("Arcane Powder")
            h:joinParty({ { class = "PRIEST" }, { class = "MAGE" } })
            h:give("Arcane Intellect")
            assert.equal("Arcane Brilliance", h:shown())
            assert.equal("party1", h:target())
        end)

        it("casts single-target when only one is missing", function()
            local h = brillianceMage()
            h:bag("Arcane Powder")
            h:joinParty({ { class = "PRIEST" } })
            h:give("Arcane Intellect")
            assert.same({ "Arcane Intellect > party1" }, h:buffUp())
        end)

        it("doesn't count classes it skips towards the group version", function()
            local h = brillianceMage()
            h:bag("Arcane Powder")
            h:joinParty({ { class = "WARRIOR" }, { class = "WARRIOR" }, { class = "ROGUE" }, { class = "PRIEST" } })
            h:give("Arcane Intellect")
            assert.same({ "Arcane Intellect > party4" }, h:buffUp())
        end)

        it("doesn't count members out of range towards the group version", function()
            local h = brillianceMage()
            h:bag("Arcane Powder")
            h:joinParty({ { class = "PRIEST", inRange = false }, { class = "MAGE" } })
            h:give("Arcane Intellect")
            assert.same({ "Arcane Intellect > party2" }, h:buffUp())
        end)

        it("needs the group version to be known", function()
            local h = mage()
            h:bag("Arcane Powder")
            h:joinParty({ { class = "PRIEST" } })
            assert.same({ "Arcane Intellect", "Arcane Intellect > party1" }, h:buffUp())
        end)

        it("uses either candle for Prayer of Fortitude", function()
            local h = Addon.load({ class = "PRIEST", known = { "Power Word: Fortitude", "Prayer of Fortitude" } })
            h:bag("Sacred Candle")
            h:joinParty({ { class = "WARRIOR" } })
            assert.same({ "Prayer of Fortitude" }, h:buffUp())
        end)
    end)

    describe("in a raid", function()
        local members = {
            { class = "PRIEST", subgroup = 1 },
            { class = "MAGE", subgroup = 2 },
            { class = "DRUID", subgroup = 2 },
        }

        it("buffs only the player's subgroup by default", function()
            local h = mage()
            h:joinRaid(members)
            assert.same({ "Arcane Intellect", "Arcane Intellect > raid2" }, h:buffUp())
        end)

        it("buffs the player's subgroup, then the rest, with whole-raid buffing", function()
            local h = mage({ config = { RAID_BUFFING = true } })
            h:joinRaid(members)
            assert.same({ "Arcane Intellect", "Arcane Intellect > raid2", "Arcane Intellect > raid3",
                "Arcane Intellect > raid4" }, h:buffUp())
        end)

        it("starts with the player's own subgroup when it isn't the first", function()
            local h = mage({ config = { RAID_BUFFING = true } })
            h:joinRaid(members, 2)
            assert.same({ "Arcane Intellect", "Arcane Intellect > raid3", "Arcane Intellect > raid4",
                "Arcane Intellect > raid2" }, h:buffUp())
        end)

        it("casts a group version per subgroup", function()
            local h = mage({ known = { "Arcane Intellect", "Arcane Brilliance" }, config = { RAID_BUFFING = true } })
            h:bag("Arcane Powder")
            h:joinRaid(members)
            assert.same({ "Arcane Brilliance", "Arcane Brilliance > raid3" }, h:buffUp())
        end)
    end)

    describe("suggestion list", function()
        it("names the member a buff goes on", function()
            local h = mage()
            h:joinParty({ { class = "PRIEST", name = "Anduin" } })
            assert.same({ "Arcane Intellect", "Arcane Intellect > Anduin" }, h:suggestions())
        end)
    end)

    describe("events", function()
        it("re-checks once for a burst of member aura changes", function()
            local h = mage()
            h:joinParty({ { class = "PRIEST" }, { class = "MAGE" } })
            local checks = 0
            local check = h.ns.CheckPlayerBuffs
            h.ns.CheckPlayerBuffs = function()
                checks = checks + 1
                check()
            end
            h:fire("UNIT_AURA", "party1", {})
            h:fire("UNIT_AURA", "party2", {})
            h:fire("UNIT_AURA", "party1", {})
            h.state:advance(0.5)
            assert.equal(1, checks)
        end)

        it("ignores member aura changes in combat without reading the payload", function()
            local h = mage()
            h:joinParty({ { class = "PRIEST" } })
            h:enterCombat()
            local timers = #h.state.timers
            local payload = setmetatable({}, { __index = function() error("payload read") end })
            h:fire("UNIT_AURA", "party1", payload)
            assert.equal(timers, #h.state.timers)
        end)

        it("ignores units outside the group", function()
            local h = mage()
            h:joinParty({ { class = "PRIEST" } })
            local timers = #h.state.timers
            h:fire("UNIT_AURA", "target", {})
            h:fire("UNIT_AURA", "nameplate1", {})
            assert.equal(timers, #h.state.timers)
        end)
    end)
end)
