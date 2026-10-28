local Addon = require("helpers.load_addon")

local ALL = { "Blessing of Might", "Blessing of Wisdom", "Blessing of Kings", "Blessing of Light" }

local function paladin(opts)
    opts = opts or {}
    opts.class = "PALADIN"
    opts.known = opts.known or ALL
    return Addon.load(opts)
end

describe("roles", function()
    it("defaults each class to its role", function()
        local h = paladin()
        local classes = {
            WARRIOR = "melee", ROGUE = "melee", HUNTER = "ranged", MAGE = "caster", WARLOCK = "caster",
            PRIEST = "healer", DRUID = "healer", SHAMAN = "healer", PALADIN = "healer",
        }
        local members = {}
        for class in pairs(classes) do table.insert(members, { class = class }) end
        h:joinRaid(members)
        h:settle()
        for unit, member in pairs(h.state.members) do
            local role, source = h.ns.RoleOf(unit)
            assert.equal(classes[member.class], role)
            assert.equal("class", source)
        end
    end)

    describe("blessings in a raid", function()
        it("follow the role's list", function()
            local h = paladin()
            h:give("Blessing of Might")
            h:joinRaid({ { class = "WARRIOR" }, { class = "HUNTER" }, { class = "MAGE" }, { class = "DRUID" } })
            h:settle()
            assert.same({ "Blessing of Might > raid2", "Blessing of Kings > raid3", "Blessing of Wisdom > raid4",
                "Blessing of Wisdom > raid5" }, h:buffUp())
        end)

        it("give the next on the role's list when another Paladin's is there", function()
            local h = paladin()
            h:give("Blessing of Might")
            h:joinRaid({ { class = "WARRIOR" }, { class = "DRUID" } })
            h:settle()
            h:give("Blessing of Might", { unit = "raid2", fromPlayer = false })
            h:give("Blessing of Wisdom", { unit = "raid3", fromPlayer = false })
            assert.same({ "Blessing of Kings > raid2", "Blessing of Kings > raid3" }, h:buffUp())
        end)

        it("give Light once nothing on the role's list is left", function()
            local h = paladin()
            h:give("Blessing of Might")
            h:joinRaid({ { class = "WARRIOR" }, { class = "PRIEST" } })
            h:settle()
            h:give("Blessing of Might", { unit = "raid2", fromPlayer = false })
            h:give("Blessing of Kings", { unit = "raid2", fromPlayer = false })
            h:give("Greater Blessing of Wisdom", { unit = "raid3", fromPlayer = false })
            h:give("Blessing of Kings", { unit = "raid3", fromPlayer = false })
            assert.same({ "Blessing of Light > raid2", "Blessing of Light > raid3" }, h:buffUp())
        end)

        it("skip Light until it's learned", function()
            local h = paladin({ known = { "Blessing of Might", "Blessing of Wisdom", "Blessing of Kings" } })
            h:give("Blessing of Might")
            h:joinRaid({ { class = "WARRIOR" } })
            h:settle()
            h:give("Blessing of Might", { unit = "raid2", fromPlayer = false })
            h:give("Blessing of Kings", { unit = "raid2", fromPlayer = false })
            assert.is_nil(h:shown())
        end)

        it("count a Greater Blessing of Light", function()
            local h = paladin()
            h:give("Blessing of Might")
            h:joinRaid({ { class = "WARRIOR" } })
            h:settle()
            h:give("Blessing of Might", { unit = "raid2", fromPlayer = false })
            h:give("Blessing of Kings", { unit = "raid2", fromPlayer = false })
            h:give("Greater Blessing of Light", { unit = "raid2", fromPlayer = false })
            assert.is_nil(h:shown())
        end)

        it("keep the player's own blessing on the setting", function()
            local h = paladin({ config = { PALADIN_BLESSING = "Blessing of Kings" } })
            h:joinRaid({})
            h:settle()
            assert.same({ "Blessing of Kings" }, h:buffUp())
        end)
    end)

    describe("/bb role", function()
        local function raid()
            local h = paladin()
            h:give("Blessing of Might")
            h:joinRaid({
                { class = "DRUID", name = "Bark Oakheart" },
                { class = "DRUID", name = "Barley Moss" },
                { class = "WARRIOR", name = "Tor Stone" },
            })
            h:settle()
            return h
        end

        it("sets a member's role by part of their name", function()
            local h = raid()
            h:slash("role oak melee")
            assert.same({ ["Bark Oakheart"] = "melee" }, h.ns.config.ROLES)
            assert.equal("melee", h.ns.RoleOf("raid2"))
            assert.equal("manual", select(2, h.ns.RoleOf("raid2")))
            assert.is_true(h:printed("Bark Oakheart is melee."))
        end)

        it("takes a full name with a space, in any case", function()
            local h = raid()
            h:slash("role barley moss CASTER")
            assert.equal("caster", h.ns.config.ROLES["Barley Moss"])
        end)

        it("changes what the member is given", function()
            local h = raid()
            h:slash("role oak melee")
            h:give("Blessing of Wisdom", { unit = "raid3" })
            h:give("Blessing of Might", { unit = "raid4" })
            assert.same({ "Blessing of Might > raid2" }, h:buffUp())
        end)

        it("lists the candidates when a name matches several", function()
            local h = raid()
            h:slash("role bar melee")
            assert.same({}, h.ns.config.ROLES)
            assert.is_true(h:printed("\"bar\" matches Bark Oakheart, Barley Moss."))
        end)

        it("says so when nobody matches", function()
            local h = raid()
            h:slash("role zed tank")
            assert.same({}, h.ns.config.ROLES)
            assert.is_true(h:printed("no raid member matches \"zed\""))
        end)

        it("clears a role, even for someone who left", function()
            local h = paladin({ saved = { ROLES = { ["Bark Oakheart"] = "melee" } } })
            h:slash("role oak")
            assert.same({}, h.ns.config.ROLES)
            assert.is_true(h:printed("Bark Oakheart's role is back to automatic."))
        end)

        it("prints the usage without a name", function()
            local h = raid()
            h:slash("role")
            assert.is_true(h:printed("/bb role <name>"))
        end)

        it("keeps roles in the account-wide settings", function()
            local h = paladin({ saved = { ROLES = { ["Tor Stone"] = "tank" } } })
            h:joinRaid({ { class = "WARRIOR", name = "Tor Stone" } })
            h:settle()
            assert.equal("tank", h.ns.RoleOf("raid2"))
            assert.equal(h.ns.config, h.env.BuffBotConfig)
        end)
    end)

    describe("group markers", function()
        local function raidOf(members)
            local h = paladin()
            h:joinRaid(members)
            h:settle()
            return h
        end

        it("make a main-tank marked member a tank", function()
            local h = raidOf({ { class = "DRUID", mainTank = true } })
            assert.same({ "tank", "mark" }, { h.ns.RoleOf("raid2") })
        end)

        it("make the player a tank when marked", function()
            local h = raidOf({})
            h.state.mainTank = true
            h.state.talents = { 31, 0, 0 }
            assert.same({ "tank", "mark" }, { h.ns.RoleOf("player") })
        end)

        it("lose to the manual list", function()
            local h = paladin({ saved = { ROLES = { Warden = "melee" } } })
            h:joinRaid({ { class = "WARRIOR", name = "Warden", mainTank = true } })
            assert.same({ "melee", "manual" }, { h.ns.RoleOf("raid2") })
        end)

        it("take the raid roster's tank and healer roles", function()
            local h = raidOf({ { class = "WARRIOR", combatRole = "TANK" }, { class = "SHAMAN", combatRole = "HEALER" },
                { class = "SHAMAN", combatRole = "DAMAGER" } })
            assert.same({ "tank", "group" }, { h.ns.RoleOf("raid2") })
            assert.same({ "healer", "group" }, { h.ns.RoleOf("raid3") })
            assert.same({ "healer", "class" }, { h.ns.RoleOf("raid4") })
        end)

        it("prefer the group finder's role where the client has one", function()
            local h = raidOf({ { class = "DRUID", combatRole = "HEALER" } })
            h.env.UnitGroupRolesAssigned = function() return "TANK" end
            assert.same({ "tank", "group" }, { h.ns.RoleOf("raid2") })
        end)

        it("give a marked tank Kings", function()
            local h = paladin()
            h:give("Blessing of Might")
            h:joinRaid({ { class = "WARRIOR", mainTank = true }, { class = "WARRIOR" } })
            h:settle()
            assert.same({ "Blessing of Kings > raid2", "Blessing of Might > raid3" }, h:buffUp())
        end)
    end)

    describe("the player's own role", function()
        it("comes from the talent tree with the most points", function()
            local h = paladin()
            h.state.talents = { 5, 31, 15 }
            assert.same({ "tank", "talents" }, { h.ns.RoleOf("player") })
        end)

        it("is the class default without talents", function()
            local h = paladin()
            assert.same({ "healer", "class" }, { h.ns.RoleOf("player") })
        end)

        it("reads the points from later clients' talent tab layout", function()
            local h = Addon.load({ class = "DRUID" })
            h.env.GetTalentTabInfo = function(tab)
                return tab, "Tree", "description", "icon", ({ 0, 30, 21 })[tab]
            end
            assert.equal("melee", h.ns.RoleOf("player"))
        end)

        it("is overridden by the manual list", function()
            local h = paladin({ saved = { ROLES = { Tester = "melee" } } })
            h.state.talents = { 31, 0, 0 }
            assert.same({ "melee", "manual" }, { h.ns.RoleOf("player") })
        end)

        it("is the class default for classes with one role", function()
            local h = Addon.load({ class = "MAGE" })
            h.state.talents = { 31, 0, 0 }
            assert.equal("caster", h.ns.RoleOf("player"))
        end)
    end)

    describe("blessings in a party", function()
        it("never give Light", function()
            local h = paladin()
            h:give("Blessing of Might")
            h:joinParty({ { class = "WARRIOR" } })
            h:give("Blessing of Might", { unit = "party1", fromPlayer = false })
            h:give("Blessing of Kings", { unit = "party1", fromPlayer = false })
            assert.is_nil(h:shown())
        end)

        it("still follow the class lists", function()
            local h = paladin()
            h:give("Blessing of Might")
            h:joinParty({ { class = "DRUID" } })
            h:give("Blessing of Wisdom", { unit = "party1", fromPlayer = false })
            h:give("Blessing of Kings", { unit = "party1", fromPlayer = false })
            assert.same({ "Blessing of Might > party1" }, h:buffUp())
        end)
    end)
end)
