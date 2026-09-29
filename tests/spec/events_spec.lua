local Addon = require("helpers.load_addon")

describe("event handling", function()
    local function mage(opts)
        opts = opts or {}
        opts.class = "MAGE"
        opts.known = { "Arcane Intellect", "Dampen Magic" }
        return Addon.load(opts)
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

    it("UNIT_AURA with removed auras re-checks", function()
        local h = mage()
        h:give("Arcane Intellect")
        h.state:removeAura("Arcane Intellect")
        h:fire("UNIT_AURA", "player", { removedAuraInstanceIDs = { 7 } })
        assert.equal("Arcane Intellect", h:shown())
    end)

    it("UNIT_AURA full update rebuilds the list in a raid", function()
        local h = mage({ raid = true })
        local before = h.ns.classBuffList
        h:fire("UNIT_AURA", "player", { isFullUpdate = true })
        assert.are_not.equal(before, h.ns.classBuffList)
    end)

    it("UNIT_AURA full update outside a raid does nothing", function()
        local h = mage()
        local before = h.ns.classBuffList
        h.state:giveAura("Arcane Intellect")
        h:fire("UNIT_AURA", "player", { isFullUpdate = true })
        assert.equal(before, h.ns.classBuffList)
        assert.equal("Arcane Intellect", h:shown())
    end)

    for _, event in ipairs({ "GROUP_ROSTER_UPDATE", "GROUP_LEFT", "SPELLS_CHANGED" }) do
        it(event .. " rebuilds the list and re-checks", function()
            local h = mage()
            local before = h.ns.classBuffList
            h.state:giveAura("Arcane Intellect")
            h:fire(event)
            assert.are_not.equal(before, h.ns.classBuffList)
            assert.equal("Dampen Magic", h:shown())
        end)
    end

    it("UNIT_SPELLCAST_SUCCEEDED from the player re-checks", function()
        local h = mage()
        h.state:giveAura("Arcane Intellect")
        h:cast("Arcane Intellect")
        assert.equal("Dampen Magic", h:shown())
    end)

    it("UNIT_SPELLCAST_SUCCEEDED from others is ignored", function()
        local h = mage()
        h.state:giveAura("Arcane Intellect")
        h:fire("UNIT_SPELLCAST_SUCCEEDED", "party1", "Cast-GUID", 1459)
        assert.equal("Arcane Intellect", h:shown())
    end)

    it("ADDON_LOADED for another addon is ignored", function()
        local h = mage()
        local config = h.ns.config
        h:fire("ADDON_LOADED", "SomeOtherAddon")
        assert.equal(config, h.ns.config)
    end)
end)
