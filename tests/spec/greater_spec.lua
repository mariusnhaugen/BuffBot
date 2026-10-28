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

    describe("in a raid", function()
        local ALL = {
            "Blessing of Might", "Blessing of Wisdom", "Blessing of Kings", "Blessing of Light",
            "Greater Blessing of Might", "Greater Blessing of Wisdom", "Greater Blessing of Kings",
            "Greater Blessing of Light", "Reagent Economy",
        }
        local function raidPaladin(opts)
            opts = opts or {}
            opts.class = "PALADIN"
            opts.known = opts.known or ALL
            return Addon.load(opts)
        end
        local function many(class, count, fields)
            local members = {}
            for _ = 1, count do
                local member = { class = class }
                for key, value in pairs(fields or {}) do member[key] = value end
                table.insert(members, member)
            end
            return members
        end

        it("casts one Greater Blessing for a class", function()
            local h = raidPaladin()
            h:joinRaid(many("PRIEST", 5))
            assert.same({ "Blessing of Might", "Greater Blessing of Wisdom > raid2" }, h:buffUp())
        end)

        it("casts a single on a class with one member", function()
            local h = raidPaladin()
            h:joinRaid({ { class = "MAGE" } })
            assert.same({ "Blessing of Might", "Blessing of Wisdom > raid2" }, h:buffUp())
        end)

        it("casts the Greater Blessings first, most missing first, then the exceptions", function()
            local h = raidPaladin({ saved = { ROLES = { ["Feral Cat"] = "melee" } } })
            local members = many("WARRIOR", 2)
            for _, member in ipairs(many("DRUID", 3)) do table.insert(members, member) end
            table.insert(members, { class = "DRUID", name = "Feral Cat" })
            h:joinRaid(members)
            assert.same({ "Blessing of Might", "Greater Blessing of Wisdom > raid4", "Greater Blessing of Might > raid2",
                "Blessing of Might > raid7" }, h:buffUp())
        end)

        it("casts the player's own buffs before the Greater Blessings", function()
            local h = raidPaladin({ config = { RIGHTEOUS_FURY = true } })
            h:learn("Righteous Fury")
            h:joinRaid(many("PRIEST", 3))
            assert.same({ "Blessing of Might", "Righteous Fury", "Greater Blessing of Wisdom > raid2" }, h:buffUp())
        end)

        it("puts the player's own blessing after a Greater Blessing on their class that would replace it", function()
            local h = raidPaladin()
            h:joinRaid(many("PALADIN", 2))
            assert.same({ "Greater Blessing of Wisdom > raid2", "Blessing of Might" }, h:buffUp())
        end)

        it("covers the player with their class's Greater Blessing when it's theirs too", function()
            local h = raidPaladin({ config = { PALADIN_BLESSING = "Blessing of Wisdom" } })
            h:joinRaid(many("PALADIN", 2))
            assert.same({ "Greater Blessing of Wisdom" }, h:buffUp())
            assert.is_not_nil(h.state.members.raid3.auras["Greater Blessing of Wisdom"])
        end)

        it("recasts the Greater Blessing for a member back from the dead", function()
            local h = raidPaladin()
            h:give("Blessing of Might")
            h:joinRaid(many("WARRIOR", 5))
            for i = 3, 6 do h:give("Greater Blessing of Might", { unit = "raid" .. i }) end
            assert.same({ "Greater Blessing of Might > raid2" }, h:buffUp())
        end)

        it("casts singles when a Greater Blessing would replace an exception and save nothing", function()
            local h = raidPaladin({ saved = { ROLES = { ["Tank One"] = "tank" } } })
            h:give("Blessing of Might")
            local members = many("WARRIOR", 3)
            table.insert(members, { class = "WARRIOR", name = "Tank One" })
            h:joinRaid(members)
            h:give("Greater Blessing of Might", { unit = "raid2" })
            h:give("Blessing of Kings", { unit = "raid5" })
            assert.same({ "Blessing of Might > raid3", "Blessing of Might > raid4" }, h:buffUp())
        end)

        it("casts a Greater Blessing over an exception when it saves casts", function()
            local h = raidPaladin({ saved = { ROLES = { ["Tank One"] = "tank" } } })
            h:give("Blessing of Might")
            local members = many("WARRIOR", 4)
            table.insert(members, { class = "WARRIOR", name = "Tank One" })
            h:joinRaid(members)
            h:give("Blessing of Kings", { unit = "raid6" })
            assert.same({ "Greater Blessing of Might > raid2", "Blessing of Kings > raid6" }, h:buffUp())
        end)

        it("casts singles without Symbol of Kings or Reagent Economy", function()
            local h = raidPaladin({ known = { "Blessing of Might", "Blessing of Wisdom", "Greater Blessing of Wisdom" } })
            h:joinRaid(many("PRIEST", 2))
            assert.same({ "Blessing of Might", "Blessing of Wisdom > raid2", "Blessing of Wisdom > raid3" }, h:buffUp())
        end)

        it("casts singles when most of the class is out of range", function()
            local h = raidPaladin()
            h:give("Blessing of Might")
            local members = many("PRIEST", 2, { inRange = false })
            table.insert(members, { class = "PRIEST" })
            h:joinRaid(members)
            assert.same({ "Blessing of Wisdom > raid4" }, h:buffUp())
        end)

        it("leaves members who already have another Paladin's blessing to the next one", function()
            local h = raidPaladin()
            h:give("Blessing of Might")
            h:joinRaid(many("PRIEST", 4))
            h:give("Blessing of Wisdom", { unit = "raid2", fromPlayer = false })
            assert.same({ "Greater Blessing of Wisdom > raid3", "Blessing of Kings > raid2" }, h:buffUp())
        end)

        it("buffs a 10-member raid with Greater Blessings before singles", function()
            local h = raidPaladin()
            h:joinRaid({
                { class = "WARRIOR", subgroup = 1 }, { class = "WARRIOR", subgroup = 1 },
                { class = "ROGUE", subgroup = 1 }, { class = "PRIEST", subgroup = 1 },
                { class = "PRIEST", subgroup = 2 }, { class = "MAGE", subgroup = 2 },
                { class = "MAGE", subgroup = 2 }, { class = "MAGE", subgroup = 2 },
                { class = "HUNTER", subgroup = 2 },
            })
            assert.same({ "Blessing of Might", "Greater Blessing of Wisdom > raid7", "Greater Blessing of Might > raid2",
                "Greater Blessing of Wisdom > raid5", "Blessing of Might > raid4", "Blessing of Kings > raid10" },
                h:buffUp())
        end)
    end)

    describe("suggestion list", function()
        local function raidWith(members, opts)
            opts = opts or {}
            opts.class = "PALADIN"
            opts.known = { "Blessing of Might", "Blessing of Wisdom", "Greater Blessing of Might",
                "Greater Blessing of Wisdom", "Reagent Economy" }
            local h = Addon.load(opts)
            h:give("Blessing of Might")
            h:joinRaid(members)
            return h
        end

        it("names the class a Greater Blessing goes on, then the members for singles", function()
            local h = raidWith({
                { class = "PRIEST" }, { class = "PRIEST" }, { class = "WARRIOR" }, { class = "WARRIOR" },
                { class = "MAGE", name = "Jaina" },
            })
            assert.same({ "Greater Blessing of Might > Warriors", "Greater Blessing of Wisdom > Priests",
                "Blessing of Wisdom > Jaina" }, h:suggestions())
        end)

        it("uses the game's class name on other clients", function()
            local h = raidWith({ { class = "PRIEST" }, { class = "PRIEST" } },
                { translate = function(name) return "DE " .. name end })
            h.state.locale = "deDE"
            h.ns.UpdateSuggestionList()
            assert.same({ "DE Greater Blessing of Wisdom > Class PRIEST" }, h:suggestions())
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
