local Addon = require("helpers.load_addon")

describe("per-class buff priority (vanilla spells)", function()
    it("DRUID: Mark of the Wild, Thorns", function()
        local h = Addon.load({ class = "DRUID", known = { "Mark of the Wild", "Thorns" } })
        assert.same({ "Mark of the Wild", "Thorns" }, h:buffUp())
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

        it("recommends Ice Armor outside a raid by default", function()
            local h = Addon.load({ class = "MAGE", known = all })
            assert.same({ "Ice Armor", "Arcane Intellect", "Dampen Magic" }, h:buffUp())
        end)

        it("recommends Mage Armor in a raid by default", function()
            local h = Addon.load({ class = "MAGE", known = all, raid = true })
            assert.same({ "Mage Armor", "Arcane Intellect", "Dampen Magic" }, h:buffUp())
        end)

        it("uses the raid pick in a raid", function()
            local h = Addon.load({ class = "MAGE", known = all, raid = true,
                config = { MAGE_ARMOR = "Mage Armor", MAGE_ARMOR_RAID = "Ice Armor" } })
            assert.equal("Ice Armor", h:shown())
        end)

        it("switches armor on joining and leaving a raid, the other armor not counting", function()
            local h = Addon.load({ class = "MAGE", known = all })
            h:give("Ice Armor")
            h:give("Arcane Intellect")
            h:give("Dampen Magic")
            assert.is_nil(h:shown())
            h:joinRaid()
            assert.equal("Mage Armor", h:buffUp()[1])
            h:leaveGroup()
            assert.is_nil(h:shown())
        end)

        it("recommends Mage Armor when picked in the settings", function()
            local h = Addon.load({ class = "MAGE", known = all, config = { MAGE_ARMOR = "Mage Armor" } })
            assert.same({ "Mage Armor", "Arcane Intellect", "Dampen Magic" }, h:buffUp())
        end)

        it("falls back to Frost Armor at low level", function()
            local h = Addon.load({ class = "MAGE", known = { "Frost Armor", "Arcane Intellect" } })
            assert.same({ "Frost Armor", "Arcane Intellect" }, h:buffUp())
        end)

        it("uses the Frost line until a picked Mage Armor is learned", function()
            local h = Addon.load({ class = "MAGE", known = { "Frost Armor", "Arcane Intellect" },
                config = { MAGE_ARMOR = "Mage Armor" } })
            assert.equal("Frost Armor", h:shown())
            h:learn("Mage Armor")
            assert.equal("Mage Armor", h:shown())
        end)

        it("offers the Frost line and Mage Armor in the settings", function()
            local h = Addon.load({ class = "MAGE", known = { "Frost Armor", "Arcane Intellect" } })
            local texts = {}
            for _, option in ipairs(h:dropdown("Mage armor")) do table.insert(texts, option.text) end
            assert.same({ "Frost Armor", "Mage Armor" }, texts)
            h:learn("Ice Armor")
            assert.equal("Ice Armor", h:dropdown("Mage armor")[1].text)
            h:learn("Mage Armor")
            h:choose("Mage armor", "Mage Armor")
            assert.equal("Mage Armor", h.ns.config.MAGE_ARMOR)
            assert.equal("Mage Armor", h:shown())
        end)

        it("offers the same armors for a raid", function()
            local h = Addon.load({ class = "MAGE", known = all, raid = true })
            local texts = {}
            for _, option in ipairs(h:dropdown("Mage armor in a raid")) do table.insert(texts, option.text) end
            assert.same({ "Ice Armor", "Mage Armor" }, texts)
            h:choose("Mage armor in a raid", "Ice Armor")
            assert.equal("Ice Armor", h.ns.config.MAGE_ARMOR_RAID)
            assert.equal("Ice Armor", h:shown())
        end)
    end)

    describe("PALADIN", function()
        it("Devotion Aura, then Blessing of Might", function()
            local h = Addon.load({ class = "PALADIN", known = { "Devotion Aura", "Blessing of Might" } })
            assert.same({ "Devotion Aura", "Blessing of Might" }, h:buffUp())
        end)

        it("recommends the aura picked in the settings", function()
            local h = Addon.load({ class = "PALADIN", known = { "Devotion Aura", "Retribution Aura" },
                config = { PALADIN_AURA = "Retribution Aura" } })
            assert.same({ "Retribution Aura" }, h:buffUp())
        end)

        it("uses Devotion Aura until the picked aura is learned", function()
            local h = Addon.load({ class = "PALADIN", known = { "Devotion Aura" },
                config = { PALADIN_AURA = "Fire Resistance Aura" } })
            assert.equal("Devotion Aura", h:shown())
            h:learn("Fire Resistance Aura")
            assert.equal("Fire Resistance Aura", h:shown())
        end)

        it("offers the auras in the settings", function()
            local h = Addon.load({ class = "PALADIN", known = { "Devotion Aura", "Retribution Aura" } })
            local texts = {}
            for _, option in ipairs(h:dropdown("Paladin aura")) do table.insert(texts, option.text) end
            assert.same({ "Retribution Aura", "Devotion Aura", "Fire Resistance Aura", "Frost Resistance Aura",
                "Shadow Resistance Aura" }, texts)
            h:choose("Paladin aura", "Retribution Aura")
            assert.equal("Retribution Aura", h.ns.config.PALADIN_AURA)
            assert.equal("Retribution Aura", h:shown())
        end)

        it("swaps to a newly picked aura once, then lets any aura count", function()
            local h = Addon.load({ class = "PALADIN", known = { "Devotion Aura", "Retribution Aura" } })
            h:give("Retribution Aura")
            assert.is_nil(h:shown())
            h:choose("Paladin aura", "Retribution Aura")
            assert.is_nil(h:shown()) -- already up: nothing to swap
            h:choose("Paladin aura", "Fire Resistance Aura")
            assert.is_nil(h:shown()) -- not learned: no swap to Devotion
            h:learn("Frost Resistance Aura")
            h:choose("Paladin aura", "Devotion Aura")
            assert.equal("Devotion Aura", h:shown())
            h:choose("Paladin aura", "Frost Resistance Aura")
            assert.equal("Frost Resistance Aura", h:shown())
            h:remove("Retribution Aura")
            h:give("Frost Resistance Aura")
            assert.is_nil(h:shown())
            -- Swapping by hand afterwards is left alone
            h:remove("Frost Resistance Aura")
            h:give("Retribution Aura")
            assert.is_nil(h:shown())
        end)

        it("swaps to a newly picked aura in a raid", function()
            local h = Addon.load({ class = "PALADIN", known = { "Devotion Aura", "Retribution Aura" } })
            h:joinRaid({ { name = "Tank", class = "WARRIOR" } })
            h:give("Retribution Aura")
            assert.is_nil(h:shown())
            h:choose("Paladin aura", "Devotion Aura")
            assert.equal("Devotion Aura", h:shown())
        end)

        it("recommends the blessing picked in the settings", function()
            local h = Addon.load({
                class = "PALADIN",
                known = { "Blessing of Might", "Blessing of Wisdom" },
                config = { PALADIN_BLESSING = "Blessing of Wisdom" },
            })
            assert.same({ "Blessing of Wisdom" }, h:buffUp())
        end)

        it("skips Righteous Fury unless the setting is on", function()
            local h = Addon.load({ class = "PALADIN", known = { "Devotion Aura", "Blessing of Might", "Righteous Fury" } })
            assert.same({ "Devotion Aura", "Blessing of Might" }, h:buffUp())
        end)

        it("recommends Righteous Fury last when RIGHTEOUS_FURY is on", function()
            local h = Addon.load({
                class = "PALADIN",
                known = { "Devotion Aura", "Blessing of Might", "Righteous Fury" },
                config = { RIGHTEOUS_FURY = true },
            })
            assert.same({ "Devotion Aura", "Blessing of Might", "Righteous Fury" }, h:buffUp())
        end)

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
