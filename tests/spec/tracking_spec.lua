local Addon = require("helpers.load_addon")

describe("tracking", function()
    -- Loads a character knowing these trackers, and lets the login casts finish
    local function load(known, opts)
        opts = opts or {}
        opts.known = known
        local h = Addon.load(opts)
        h.state:advance(11)
        return h
    end

    local function on(h, name)
        return h.state.auras[name] ~= nil
    end

    -- Runs the retry loop to the end
    local function settle(h)
        h.state:advance(11)
    end

    describe("default tracker", function()
        for _, case in ipairs({
            { known = { "Find Minerals", "Find Herbs", "Track Beasts" }, expected = "Find Minerals" },
            { known = { "Find Herbs", "Track Beasts" }, expected = "Find Herbs" },
            { known = { "Track Beasts", "Track Humanoids" }, expected = "Track Beasts" },
        }) do
            it("is " .. case.expected .. " with " .. table.concat(case.known, ", "), function()
                local h = load(case.known)
                assert.is_true(on(h, case.expected))
                assert.same({ case.expected }, h.state.casts)
                assert.equal("", h.ns.charConfig.TRACKER)
            end)
        end

        it("is Off with no gathering tracker or Track Beasts", function()
            local h = load({ "Track Humanoids" })
            settle(h)
            assert.same({}, h.state.casts)
            assert.equal("Default (Off)", h:dropdown("Auto tracking")[1].text)
        end)

        it("follows a newly learned profession", function()
            local h = load({})
            assert.equal("Default (Off)", h:dropdown("Auto tracking")[1].text)
            h:learn("Find Herbs")
            assert.is_true(on(h, "Find Herbs"))
            assert.equal("Default (Find Herbs)", h:dropdown("Auto tracking")[1].text)
        end)
    end)

    describe("dropdown", function()
        it("lists Default, the known trackers in order, and Off", function()
            local h = load({ "Track Humanoids", "Find Herbs", "Track Beasts" })
            local texts = {}
            for _, option in ipairs(h:dropdown("Auto tracking")) do table.insert(texts, option.text) end
            assert.same({ "Default (Find Herbs)", "Find Herbs", "Track Beasts", "Track Humanoids", "Off" }, texts)
            assert.equal("Default (Find Herbs)", h:selected("Auto tracking"))
        end)

        it("switches to a picked tracker straight away, and saves it", function()
            local h = load({ "Find Minerals", "Find Herbs" })
            h.state:advance(2)
            h:choose("Auto tracking", "Find Herbs")
            assert.is_true(on(h, "Find Herbs"))
            assert.is_false(on(h, "Find Minerals"))
            assert.equal("Find Herbs", h.env.BuffBotCharConfig.TRACKER)
        end)

        it("switches to the default tracker when Default is picked again", function()
            local h = load({ "Find Minerals", "Find Herbs" }, { charSaved = { TRACKER = "Find Herbs" } })
            h:choose("Auto tracking", "Default (Find Minerals)")
            assert.is_true(on(h, "Find Minerals"))
            assert.is_false(on(h, "Find Herbs"))
            assert.equal("", h.env.BuffBotCharConfig.TRACKER)
        end)

        it("Off turns nothing off, and stops casting after a res", function()
            local h = load({ "Find Minerals" })
            h:choose("Auto tracking", "Off")
            assert.is_true(on(h, "Find Minerals"))
            h.state:removeAura("Find Minerals")
            h:die()
            h:resurrect()
            settle(h)
            assert.is_false(on(h, "Find Minerals"))
        end)
    end)

    describe("saved tracker", function()
        it("is cast over the default", function()
            local h = load({ "Find Minerals", "Find Herbs" }, { charSaved = { TRACKER = "Find Herbs" } })
            assert.same({ "Find Herbs" }, h.state.casts)
        end)

        it("falls back to the default once it's no longer known", function()
            local h = load({ "Find Minerals" }, { charSaved = { TRACKER = "Find Herbs" } })
            assert.same({ "Find Minerals" }, h.state.casts)
        end)
    end)

    describe("when it runs", function()
        it("leaves another known tracker on", function()
            local h = load({ "Find Minerals", "Track Beasts" })
            h.state:removeAura("Find Minerals")
            h.state:giveAura("Track Beasts", { duration = 0 })
            h:die()
            h:resurrect()
            settle(h)
            assert.is_true(on(h, "Track Beasts"))
            assert.is_false(on(h, "Find Minerals"))
        end)

        it("turns tracking back on after a res", function()
            local h = load({ "Find Minerals" })
            h:die()
            h.state:removeAura("Find Minerals")
            h:releaseSpirit()
            assert.is_false(on(h, "Find Minerals"))
            h:resurrect()
            assert.is_true(on(h, "Find Minerals"))
        end)

        it("doesn't turn tracking back on when the player turns it off", function()
            local h = load({ "Find Minerals" })
            h:remove("Find Minerals")
            settle(h)
            assert.is_false(on(h, "Find Minerals"))
        end)

        it("doesn't run again when the spellbook changes without a new tracker", function()
            local h = load({ "Find Minerals" })
            h.state:removeAura("Find Minerals")
            h:learn("Battle Shout")
            settle(h)
            assert.is_false(on(h, "Find Minerals"))
        end)

        it("waits until combat ends", function()
            local h = load({ "Find Minerals" })
            h.state:removeAura("Find Minerals")
            h:enterCombat()
            h:resurrect()
            settle(h)
            assert.is_false(on(h, "Find Minerals"))
            h:leaveCombat()
            assert.is_true(on(h, "Find Minerals"))
        end)
    end)

    describe("battlegrounds", function()
        it("casts nothing there, even after a res", function()
            local h = load({ "Find Minerals" })
            h.state:removeAura("Find Minerals")
            h.state.instanceType = "pvp"
            h:fire("PLAYER_ENTERING_WORLD")
            h:die()
            h:resurrect()
            settle(h)
            assert.is_false(on(h, "Find Minerals"))
        end)

        it("turns tracking back on after leaving", function()
            local h = load({ "Find Minerals" })
            h.state:removeAura("Find Minerals")
            h.state.instanceType = "pvp"
            h:fire("PLAYER_ENTERING_WORLD")
            h.state.instanceType = "none"
            h:fire("PLAYER_ENTERING_WORLD")
            assert.is_true(on(h, "Find Minerals"))
        end)
    end)

    describe("Find Treasure", function()
        it("is cast after the other tracker, once the global cooldown ends", function()
            local h = Addon.load({ known = { "Find Minerals", "Find Treasure" } })
            assert.same({ "Find Minerals" }, h.state.casts)
            h.state:advance(1)
            assert.same({ "Find Minerals" }, h.state.casts)
            h.state:advance(1)
            assert.same({ "Find Minerals", "Find Treasure" }, h.state.casts)
            assert.is_true(on(h, "Find Minerals"))
            assert.is_true(on(h, "Find Treasure"))
        end)

        it("is not cast with the setting off", function()
            local h = load({ "Find Treasure" }, { saved = { TRACK_TREASURE = false } })
            settle(h)
            assert.same({}, h.state.casts)
        end)

        it("is cast when the setting is ticked", function()
            local h = load({ "Find Treasure" }, { saved = { TRACK_TREASURE = false } })
            h:settingNamed("Auto Find Treasure"):SetValue(true)
            assert.is_true(on(h, "Find Treasure"))
        end)
    end)

    describe("retries", function()
        it("waits out the global cooldown instead of casting into it", function()
            local h = load({ "Find Minerals" })
            h.state:removeAura("Find Minerals")
            h.state.gcdUntil = h.state.time + 1.5
            h:resurrect()
            assert.same({ "Find Minerals" }, h.state.casts) -- only the login cast
            h.state:advance(1)
            assert.same({ "Find Minerals" }, h.state.casts)
            h.state:advance(0.5)
            assert.is_true(on(h, "Find Minerals"))
        end)

        it("waits while the player is casting", function()
            local h = load({ "Find Minerals" })
            h.state:removeAura("Find Minerals")
            h.state.casting = true
            h:resurrect()
            h.state:advance(2)
            assert.is_false(on(h, "Find Minerals"))
            h.state.casting = false
            h.state:advance(0.5)
            assert.is_true(on(h, "Find Minerals"))
        end)

        it("gives up after 10 seconds", function()
            local h = load({ "Find Minerals" })
            h.state:removeAura("Find Minerals")
            h.state.casting = true
            h:resurrect()
            h.state:advance(11)
            h.state.casting = false
            h.state:advance(60)
            assert.is_false(on(h, "Find Minerals"))
        end)
    end)
end)
