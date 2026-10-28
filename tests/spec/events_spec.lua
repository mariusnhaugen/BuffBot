local Addon = require("helpers.load_addon")

describe("event handling", function()
    local function mage(opts)
        opts = opts or {}
        opts.class = "MAGE"
        opts.known = { "Arcane Intellect", "Dampen Magic" }
        return Addon.load(opts)
    end

    -- Wearing the armor for where they are, with Arcane Intellect to cast. The
    -- armor is strict, so a rebuilt list asks for the armor of the new place.
    local function armored(inRaid)
        local h = Addon.load({
            class = "MAGE",
            known = { "Ice Armor", "Mage Armor", "Arcane Intellect" },
            config = { STRICT_ARMOR = true },
            raid = inRaid,
        })
        h:give(inRaid and "Mage Armor" or "Ice Armor")
        assert.equal("Arcane Intellect", h:shown())
        return h
    end

    -- Joins or leaves a raid without the roster event
    local function setRaid(h, inRaid)
        h.state.group, h.state.raid = inRaid, inRaid
    end

    it("UNIT_AURA for the player re-checks", function()
        local h = mage()
        h.state:giveAura("Arcane Intellect")
        h:fire("UNIT_AURA", "player", {})
        assert.equal("Dampen Magic", h:shown())
    end)

    it("UNIT_AURA for another unit is ignored", function()
        local h = mage()
        h.state:giveAura("Arcane Intellect")
        h:fire("UNIT_AURA", "party1", {})
        assert.equal("Arcane Intellect", h:shown())
    end)

    it("UNIT_AURA for another unit doesn't read its payload, which can be secret in combat", function()
        local h = mage()
        h:fire("UNIT_AURA", "target", h.state.untouchable())
        assert.equal("Arcane Intellect", h:shown())
    end)

    it("UNIT_AURA with a secret full update re-checks without rebuilding", function()
        local h = armored(false)
        setRaid(h, true)
        h.state:giveAura("Arcane Intellect")
        h:fire("UNIT_AURA", "player", { isFullUpdate = h.state.SECRET })
        assert.is_nil(h:shown())
    end)

    it("UNIT_AURA with removed auras re-checks", function()
        local h = mage()
        h:give("Arcane Intellect")
        h.state:removeAura("Arcane Intellect")
        h:fire("UNIT_AURA", "player", { removedAuraInstanceIDs = { 7 } })
        assert.equal("Arcane Intellect", h:shown())
    end)

    it("UNIT_AURA full update rebuilds the list in a raid", function()
        local h = armored(false)
        setRaid(h, true)
        h:fire("UNIT_AURA", "player", { isFullUpdate = true })
        assert.equal("Mage Armor", h:shown())
    end)

    it("UNIT_AURA full update outside a raid re-checks without rebuilding", function()
        local h = armored(true)
        setRaid(h, false)
        h.state:giveAura("Arcane Intellect")
        h:fire("UNIT_AURA", "player", { isFullUpdate = true })
        assert.is_nil(h:shown())
    end)

    it("GROUP_ROSTER_UPDATE rebuilds the list", function()
        local h = armored(false)
        setRaid(h, true)
        h:fire("GROUP_ROSTER_UPDATE")
        assert.equal("Mage Armor", h:shown())
    end)

    it("GROUP_LEFT rebuilds the list", function()
        local h = armored(true)
        setRaid(h, false)
        h:fire("GROUP_LEFT")
        assert.equal("Ice Armor", h:shown())
    end)

    it("SPELLS_CHANGED rebuilds the list", function()
        local h = mage()
        h:give("Arcane Intellect")
        h:give("Dampen Magic")
        h.state:learn("Ice Armor")
        h:fire("SPELLS_CHANGED")
        assert.equal("Ice Armor", h:shown())
    end)

    it("ADDON_LOADED for another addon is ignored", function()
        local h = mage()
        local config = h.ns.config
        h:fire("ADDON_LOADED", "SomeOtherAddon")
        assert.equal(config, h.ns.config)
    end)
end)
