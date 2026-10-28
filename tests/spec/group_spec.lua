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

        it("doesn't poll for range when everyone in view is in range", function()
            local h = mage()
            h:joinParty({ { class = "PRIEST" }, { class = "DRUID", visible = false } })
            h:buffUp()
            assert.same({}, h.state.timers)
        end)

        it("stops polling for range once the member out of range is buffed", function()
            local h = mage()
            h:joinParty({ { class = "PRIEST", inRange = false } })
            h:buffUp()
            h:give("Arcane Intellect", { unit = "party1" })
            h.state:advance(2)
            assert.same({}, h.state.timers)
        end)

        it("picks up a member coming into view from their aura event", function()
            local h = mage()
            h:joinParty({ { class = "PRIEST", visible = false } })
            h:buffUp()
            h.state.members.party1.visible = true
            h:auraChanged("party1")
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
    end)

    describe("Paladin blessings", function()
        local function paladin(opts)
            opts = opts or {}
            opts.class = "PALADIN"
            opts.known = opts.known or { "Blessing of Might", "Blessing of Wisdom" }
            return Addon.load(opts)
        end

        it("gives Warriors and Rogues Might", function()
            local h = paladin()
            h:joinParty({ { class = "WARRIOR" }, { class = "ROGUE" } })
            assert.same({ "Blessing of Might", "Blessing of Might > party1", "Blessing of Might > party2" },
                h:buffUp())
        end)

        it("gives casters, Druids, Shamans, Hunters and other Paladins Wisdom", function()
            local h = paladin()
            h:joinParty({ { class = "MAGE" }, { class = "DRUID" }, { class = "SHAMAN" }, { class = "PALADIN" } })
            h:give("Blessing of Might")
            assert.same({ "Blessing of Wisdom > party1", "Blessing of Wisdom > party2", "Blessing of Wisdom > party3",
                "Blessing of Wisdom > party4" }, h:buffUp())
            local hunter = paladin()
            hunter:joinParty({ { class = "HUNTER" } })
            hunter:give("Blessing of Might")
            assert.same({ "Blessing of Wisdom > party1" }, hunter:buffUp())
        end)

        it("gives Hunters and other Paladins Kings once it's learned", function()
            local h = paladin({ known = { "Blessing of Might", "Blessing of Wisdom", "Blessing of Kings" } })
            h:joinParty({ { class = "HUNTER" }, { class = "PALADIN" }, { class = "MAGE" }, { class = "WARRIOR" } })
            assert.same({ "Blessing of Might", "Blessing of Kings > party1", "Blessing of Kings > party2",
                "Blessing of Wisdom > party3", "Blessing of Might > party4" }, h:buffUp())
        end)

        it("gives Hunters Wisdom before Kings is learned, and Kings when Wisdom is due", function()
            local h = paladin()
            h:joinParty({ { class = "HUNTER" } })
            assert.same({ "Blessing of Might", "Blessing of Wisdom > party1" }, h:buffUp())
            h:learn("Blessing of Kings")
            assert.same({}, h:buffUp())
            h:give("Blessing of Wisdom", { unit = "party1", duration = 3600, remaining = 200 })
            assert.equal("Blessing of Kings", h:shown())
            assert.equal("party1", h:target())
        end)

        it("counts a Greater Blessing of Kings", function()
            local h = paladin({ known = { "Blessing of Might", "Blessing of Wisdom", "Blessing of Kings" } })
            h:joinParty({ { class = "HUNTER" } })
            h:give("Blessing of Might")
            h:give("Greater Blessing of Kings", { unit = "party1" })
            assert.is_nil(h:shown())
        end)

        it("puts Kings on the player when picked, and the class blessings on the party", function()
            local h = paladin({ known = { "Blessing of Might", "Blessing of Wisdom", "Blessing of Kings" },
                config = { PALADIN_BLESSING = "Blessing of Kings" } })
            h:joinParty({ { class = "WARRIOR" }, { class = "PRIEST" } })
            assert.same({ "Blessing of Kings", "Blessing of Might > party1", "Blessing of Wisdom > party2" },
                h:buffUp())
        end)

        it("falls back to Might on the player until the picked blessing is learned", function()
            local h = paladin({ known = { "Blessing of Might" }, config = { PALADIN_BLESSING = "Blessing of Kings" } })
            assert.same({ "Blessing of Might" }, h:buffUp())
            h:learn("Blessing of Kings")
            assert.same({ "Blessing of Kings" }, h:buffUp())
        end)

        it("offers Might, Wisdom and Kings in the settings", function()
            local h = paladin()
            local texts = {}
            for _, option in ipairs(h:dropdown("Paladin blessing on yourself")) do table.insert(texts, option.text) end
            assert.same({ "Blessing of Might", "Blessing of Wisdom", "Blessing of Kings" }, texts)
            h:choose("Paladin blessing on yourself", "Blessing of Wisdom")
            assert.equal("Blessing of Wisdom", h.ns.config.PALADIN_BLESSING)
            assert.equal("Blessing of Wisdom", h:shown())
        end)

        it("keeps the player's own blessing on the setting", function()
            local h = paladin({ config = { PALADIN_BLESSING = "Blessing of Wisdom" } })
            h:joinParty({ { class = "WARRIOR" }, { class = "PRIEST" } })
            assert.same({ "Blessing of Wisdom", "Blessing of Might > party1", "Blessing of Wisdom > party2" },
                h:buffUp())
        end)

        it("skips members whose blessing isn't learned yet", function()
            local h = paladin({ known = { "Blessing of Might" } })
            h:joinParty({ { class = "MAGE" }, { class = "WARRIOR" } })
            assert.same({ "Blessing of Might", "Blessing of Might > party2" }, h:buffUp())
        end)

        it("counts another Paladin's blessing", function()
            local h = paladin()
            h:joinParty({ { class = "WARRIOR" } })
            h:give("Blessing of Might")
            h:give("Blessing of Might", { unit = "party1", fromPlayer = false })
            assert.is_nil(h:shown())
        end)

        it("gives the next blessing on the list when another Paladin's is there", function()
            local h = paladin({ known = { "Blessing of Might", "Blessing of Wisdom", "Blessing of Kings" } })
            h:joinParty({ { class = "WARRIOR" }, { class = "HUNTER" }, { class = "MAGE" } })
            h:give("Blessing of Might")
            h:give("Blessing of Might", { unit = "party1", fromPlayer = false })
            h:give("Blessing of Kings", { unit = "party2", fromPlayer = false })
            h:give("Greater Blessing of Wisdom", { unit = "party3", fromPlayer = false })
            assert.same({ "Blessing of Kings > party1", "Blessing of Wisdom > party2", "Blessing of Kings > party3" },
                h:buffUp())
        end)

        it("skips a member who has every blessing on their list from other Paladins", function()
            local h = paladin({ known = { "Blessing of Might", "Blessing of Wisdom", "Blessing of Kings" } })
            h:joinParty({ { class = "WARRIOR" } })
            h:give("Blessing of Might")
            h:give("Blessing of Might", { unit = "party1", fromPlayer = false })
            h:give("Blessing of Kings", { unit = "party1", fromPlayer = false })
            assert.is_nil(h:shown())
        end)

        it("keeps its blessing on a member until it's due, then picks again", function()
            local h = paladin({ known = { "Blessing of Might", "Blessing of Wisdom", "Blessing of Kings" } })
            h:joinParty({ { class = "WARRIOR" } })
            h:give("Blessing of Might")
            h:give("Blessing of Might", { unit = "party1", fromPlayer = false })
            assert.same({ "Blessing of Kings > party1" }, h:buffUp())
            h:remove("Blessing of Might", "party1")
            assert.is_nil(h:shown())
            h:give("Blessing of Kings", { unit = "party1", duration = 3600, remaining = 200 })
            assert.equal("Blessing of Might", h:shown())
            assert.equal("party1", h:target())
        end)

        it("refreshes its blessing on a member when it's still the pick", function()
            local h = paladin()
            h:joinParty({ { class = "WARRIOR" } })
            h:give("Blessing of Might")
            h:give("Blessing of Might", { unit = "party1", duration = 3600, remaining = 200 })
            assert.equal("Blessing of Might", h:shown())
            assert.equal("party1", h:target())
        end)

        it("falls back to the Paladin list on the player when the picked blessing is someone else's", function()
            local h = paladin({ known = { "Blessing of Might", "Blessing of Wisdom", "Blessing of Kings" } })
            h:give("Blessing of Might", { fromPlayer = false })
            assert.same({ "Blessing of Kings" }, h:buffUp())
            h:remove("Blessing of Might")
            assert.equal("Blessing of Might", h:shown())
        end)

        it("counts a Greater Blessing", function()
            local h = paladin()
            h:joinParty({ { class = "WARRIOR" } })
            h:give("Blessing of Might")
            h:give("Greater Blessing of Might", { unit = "party1" })
            assert.is_nil(h:shown())
        end)

        it("never casts a Greater Blessing", function()
            local h = paladin({ known = { "Blessing of Might", "Blessing of Wisdom", "Greater Blessing of Might" } })
            h:learn("Reagent Economy")
            h:joinParty({ { class = "WARRIOR" }, { class = "ROGUE" } })
            assert.same({ "Blessing of Might", "Blessing of Might > party1", "Blessing of Might > party2" },
                h:buffUp())
        end)

        it("is player-only with group buffing turned off", function()
            local h = paladin({ config = { GROUP_BUFFING = false } })
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

        it("buffs the player's subgroup, then the rest of the raid", function()
            local h = mage()
            h:joinRaid(members)
            assert.same({ "Arcane Intellect", "Arcane Intellect > raid2", "Arcane Intellect > raid3",
                "Arcane Intellect > raid4" }, h:buffUp())
        end)

        it("starts with the player's own subgroup when it isn't the first", function()
            local h = mage()
            h:joinRaid(members, 2)
            assert.same({ "Arcane Intellect", "Arcane Intellect > raid3", "Arcane Intellect > raid4",
                "Arcane Intellect > raid2" }, h:buffUp())
        end)

        it("casts a group version per subgroup", function()
            local h = mage({ known = { "Arcane Intellect", "Arcane Brilliance" } })
            h:bag("Arcane Powder")
            h:joinRaid(members)
            assert.same({ "Arcane Brilliance", "Arcane Brilliance > raid3" }, h:buffUp())
        end)

        it("is player-only with group buffing turned off", function()
            local h = mage({ config = { GROUP_BUFFING = false } })
            h:joinRaid(members)
            assert.same({ "Arcane Intellect" }, h:buffUp())
        end)

        it("is player-only in a battleground or arena", function()
            for _, instanceType in ipairs({ "pvp", "arena" }) do
                local h = mage()
                h.state.instanceType = instanceType
                h:joinRaid(members)
                assert.same({ "Arcane Intellect" }, h:buffUp())
            end
        end)

        it("buffs the raid again after leaving a battleground", function()
            local h = mage()
            h.state.instanceType = "pvp"
            h:joinRaid(members)
            h:give("Arcane Intellect")
            assert.is_nil(h:shown())
            h.state.instanceType = "none"
            h:fire("PLAYER_ENTERING_WORLD")
            assert.equal("Arcane Intellect", h:shown())
            assert.equal("raid2", h:target())
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
