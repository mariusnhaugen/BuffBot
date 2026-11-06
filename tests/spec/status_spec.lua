local Addon = require("helpers.load_addon")

-- Lines printed after the call, so the load message doesn't count
local function printedBy(h, fn)
    local before = #h.state.printed
    fn()
    local lines = {}
    for i = before + 1, #h.state.printed do table.insert(lines, h.state.printed[i]) end
    return lines
end

local function has(lines, text)
    for _, line in ipairs(lines) do
        if line:find(text, 1, true) then return true end
    end
    return false
end

describe("/bb status", function()
    it("prints the version, the player and the list", function()
        local h = Addon.load({ class = "MAGE", known = { "Arcane Intellect" } })
        local lines = printedBy(h, function() h:slash("status") end)
        assert.is_true(has(lines, "BuffBot 2."))
        assert.is_true(has(lines, "You: level 60 Mage, solo, open world; buff your group on"))
        assert.is_true(has(lines, "List: Arcane Intellect"))
        assert.is_true(has(lines, "Next: Arcane Intellect on you"))
    end)

    it("says why a spell is left off the list", function()
        local h = Addon.load({ class = "PALADIN", known = { "Devotion Aura", "Blessing of Might", "Righteous Fury" } })
        local lines = printedBy(h, function() h:slash("status") end)
        assert.is_true(has(lines, "Left off: Righteous Fury (off in settings), Oath of Light (not known, spell 1328548)"))
    end)

    it("names members, not unit tokens", function()
        local h = Addon.load({ class = "MAGE", known = { "Arcane Intellect" } })
        h:give("Arcane Intellect")
        h:joinParty({ { class = "PRIEST", name = "Ann Light" } })
        local lines = printedBy(h, function() h:slash("status") end)
        assert.is_true(has(lines, "party of 2"))
        assert.is_true(has(lines, "Next: Arcane Intellect on Ann Light"))
    end)

    it("says why the button is quiet", function()
        local h = Addon.load({ class = "MAGE", known = { "Arcane Intellect" } })
        h:give("Arcane Intellect")
        local lines = printedBy(h, function() h:slash("status") end)
        assert.is_true(has(lines, "Nothing to cast: everything is up"))
    end)

    it("says when a boss fight keeps the button quiet", function()
        local h = Addon.load({ class = "MAGE", known = { "Arcane Intellect" } })
        h:startEncounter()
        local lines = printedBy(h, function() h:slash("status") end)
        assert.is_true(has(lines, "Nothing to cast: in a boss fight, it waits until after"))
    end)

    it("says why a buff of the player's own is skipped", function()
        local h = Addon.load({ class = "ROGUE" })
        h:equipOffHand(2092)
        local lines = printedBy(h, function() h:slash("status") end)
        assert.is_true(has(lines, "Skipped: Main Hand Poison (none in your bags), Off Hand Poison (none in your bags)"))
    end)

    it("says where Oath of Light goes", function()
        local h = Addon.load({ class = "PALADIN", known = { "Oath of Light" } })
        h.state.instanceType = "party"
        h:joinParty({ { class = "MAGE" } })
        local lines = printedBy(h, function() h:slash("status") end)
        assert.is_true(has(lines, "Oath of Light: for your target, no tank found"))
    end)

    it("shows the player's blessing slot", function()
        local h = Addon.load({ class = "PALADIN", known = { "Blessing of Might", "Blessing of Kings" } })
        h.state.random = function() return 0.5 end
        h:joinRaid({ { class = "PALADIN", name = "Zed Peer" }, { class = "WARRIOR" } })
        h:receive("Zed Peer", "BB:v1:MW")
        h:settle()
        local lines = printedBy(h, function() h:slash("status") end)
        assert.is_true(has(lines, "Blessing slot: Kings, with 1 other BuffBot Paladin"))
        assert.is_true(has(lines, "Roles: /bb raid"))
    end)
end)

describe("debug log", function()
    local function mage()
        return Addon.load({ class = "MAGE", known = { "Arcane Intellect" }, config = { DEBUG_MODE = true } })
    end

    it("starts each line with BuffBot", function()
        local h = mage()
        assert.is_true(h:printed("BuffBot:|r next: Arcane Intellect on you"))
    end)

    it("logs the next cast once, not on every check", function()
        local h = mage()
        local lines = printedBy(h, function()
            h.ns.CheckPlayerBuffs()
            h.ns.CheckPlayerBuffs()
        end)
        assert.same({}, lines)
    end)

    it("logs when the button goes quiet", function()
        local h = mage()
        local lines = printedBy(h, function() h:give("Arcane Intellect") end)
        assert.is_true(has(lines, "nothing to cast: everything is up"))
    end)

    it("logs the list and what's left off it when it changes", function()
        local h = Addon.load({ class = "PALADIN", known = { "Devotion Aura" }, config = { DEBUG_MODE = true } })
        assert.is_true(h:printed("list: Devotion Aura"))
        assert.is_true(h:printed("Oath of Light (not known, spell 1328548)"))
        local lines = printedBy(h, function() h:fire("SPELLS_CHANGED") end)
        assert.is_false(has(lines, "list:"))
    end)

    it("logs slot changes", function()
        local h = Addon.load({ class = "PALADIN", known = { "Blessing of Might", "Blessing of Kings" },
            config = { DEBUG_MODE = true } })
        h.state.random = function() return 0.5 end
        h:joinRaid({ { class = "PALADIN", name = "Zed Peer" } })
        h:receive("Zed Peer", "BB:v1:MW")
        h:settle()
        assert.is_true(h:printed("slot: reserve -> Kings"))
    end)
end)
