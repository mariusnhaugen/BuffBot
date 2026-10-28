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
            assert.same({ "Blessing of Might > raid2", "Blessing of Kings > raid3", "Blessing of Wisdom > raid4",
                "Blessing of Wisdom > raid5" }, h:buffUp())
        end)

        it("give the next on the role's list when another Paladin's is there", function()
            local h = paladin()
            h:give("Blessing of Might")
            h:joinRaid({ { class = "WARRIOR" }, { class = "DRUID" } })
            h:give("Blessing of Might", { unit = "raid2", fromPlayer = false })
            h:give("Blessing of Wisdom", { unit = "raid3", fromPlayer = false })
            assert.same({ "Blessing of Kings > raid2", "Blessing of Kings > raid3" }, h:buffUp())
        end)

        it("give Light once nothing on the role's list is left", function()
            local h = paladin()
            h:give("Blessing of Might")
            h:joinRaid({ { class = "WARRIOR" }, { class = "PRIEST" } })
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
            h:give("Blessing of Might", { unit = "raid2", fromPlayer = false })
            h:give("Blessing of Kings", { unit = "raid2", fromPlayer = false })
            assert.is_nil(h:shown())
        end)

        it("count a Greater Blessing of Light", function()
            local h = paladin()
            h:give("Blessing of Might")
            h:joinRaid({ { class = "WARRIOR" } })
            h:give("Blessing of Might", { unit = "raid2", fromPlayer = false })
            h:give("Blessing of Kings", { unit = "raid2", fromPlayer = false })
            h:give("Greater Blessing of Light", { unit = "raid2", fromPlayer = false })
            assert.is_nil(h:shown())
        end)

        it("keep the player's own blessing on the setting", function()
            local h = paladin({ config = { PALADIN_BLESSING = "Blessing of Kings" } })
            h:joinRaid({})
            assert.same({ "Blessing of Kings" }, h:buffUp())
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
