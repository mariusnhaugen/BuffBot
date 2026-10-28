local Raid = require("helpers.raid")

-- Independent clients on one message bus end up agreeing on the slots.
-- Names sort Ann < Bob < Cid < Dan < Eve.
describe("raid coordination across clients", function()
    local VALID = {
        [1] = { "-" },
        [2] = { "K", "MW" },
        [3] = { "K", "M", "W" },
        [4] = { "K", "L", "M", "W" },
    }

    -- Every client holds a different slot, the set fits the Paladin count, and
    -- each client's view of the others matches what they hold
    local function assertAgreed(raid)
        local slots, all, count = raid:slots(), {}, 0
        for _, slot in pairs(slots) do
            table.insert(all, slot)
            count = count + 1
        end
        table.sort(all)
        local expected = { unpack(VALID[math.min(count, 4)]) }
        for _ = 5, count do table.insert(expected, 1, "-") end
        assert.same(expected, all)
        for name, view in pairs(raid:views()) do
            local others = {}
            for other, slot in pairs(slots) do
                if other ~= name and slot ~= "-" then table.insert(others, slot) end
            end
            table.sort(others)
            assert.same(others, view, name .. "'s view")
        end
        assert.equal(0, raid.dropped)
    end

    it("forms with two Paladins", function()
        local raid = Raid.new()
        raid:join("Ann Light", "Bob Stone")
        raid:run(5)
        assert.same({ ["Ann Light"] = "K", ["Bob Stone"] = "MW" }, raid:slots())
        assert.same({ "BB?:v1:-", "BB:v1:K" }, raid.clients["Ann Light"]:sent())
        assertAgreed(raid)
    end)

    it("splits Might/Wisdom when a third joins", function()
        local raid = Raid.new()
        raid:join("Ann Light", "Bob Stone")
        raid:run(5)
        raid:join("Cid Oak")
        raid:run(5)
        assert.same({ ["Ann Light"] = "K", ["Bob Stone"] = "W", ["Cid Oak"] = "M" }, raid:slots())
        assertAgreed(raid)
    end)

    it("gives a fourth Light and makes a fifth a reserve", function()
        local raid = Raid.new()
        raid:join("Ann Light", "Bob Stone", "Cid Oak")
        raid:run(5)
        raid:join("Dan Ash")
        raid:run(5)
        assert.equal("L", raid:slots()["Dan Ash"])
        raid:join("Eve Elm")
        raid:run(5)
        assert.equal("-", raid:slots()["Eve Elm"])
        assertAgreed(raid)
    end)

    it("lets newcomers joining at once share the free slots", function()
        local raid = Raid.new()
        raid:join("Bob Stone")
        raid:run(5)
        raid:join("Ann Light", "Cid Oak")
        raid:run(5)
        assertAgreed(raid)
    end)

    it("fills a freed slot with the reserve", function()
        local raid = Raid.new()
        raid:join("Ann Light", "Bob Stone", "Cid Oak", "Dan Ash", "Eve Elm")
        raid:run(5)
        assert.equal("-", raid:slots()["Eve Elm"])
        raid:leave("Bob Stone")
        raid:run(5)
        assert.equal("W", raid:slots()["Eve Elm"])
        assertAgreed(raid)
    end)

    it("closes up as Paladins leave, down to one", function()
        local raid = Raid.new()
        raid:join("Ann Light", "Bob Stone", "Cid Oak", "Dan Ash")
        raid:run(5)
        raid:leave("Bob Stone")
        raid:run(5)
        assert.same({ ["Ann Light"] = "K", ["Cid Oak"] = "M", ["Dan Ash"] = "W" }, raid:slots())
        assertAgreed(raid)
        raid:leave("Ann Light")
        raid:run(5)
        assert.same({ ["Cid Oak"] = "K", ["Dan Ash"] = "MW" }, raid:slots())
        assertAgreed(raid)
        raid:leave("Cid Oak")
        raid:run(5)
        assert.same({ ["Dan Ash"] = "-" }, raid:slots())
    end)

    it("frees the slot of a Paladin who goes offline", function()
        local raid = Raid.new()
        raid:join("Ann Light", "Bob Stone", "Cid Oak")
        raid:run(5)
        raid:goOffline("Cid Oak")
        raid:run(5)
        assert.same({ ["Ann Light"] = "K", ["Bob Stone"] = "MW" }, raid:slots())
        assertAgreed(raid)
    end)

    it("keeps a reloading Paladin's slot", function()
        local raid = Raid.new()
        raid:join("Ann Light", "Bob Stone", "Cid Oak")
        raid:run(5)
        raid:reload("Bob Stone")
        raid:run(5)
        assert.same({ ["Ann Light"] = "K", ["Bob Stone"] = "W", ["Cid Oak"] = "M" }, raid:slots())
        assertAgreed(raid)
    end)
end)
