local Addon = require("helpers.load_addon")

-- The slot rules (docs/plan/SPEC.md "Slot rules"). Names sort A < B < C < D < E.
describe("slot rules", function()
    local NextSlot
    setup(function()
        NextSlot = Addon.load({ class = "PALADIN" }).ns.NextSlot
    end)

    local settle = { kind = "settle" }
    local function claim(name) return { kind = "claim", name = name } end
    local function left(name, slot) return { kind = "peerLeft", name = name, slot = slot } end

    -- { rule, me, my slot, peers, event, expected slot }
    local rows = {
        -- Alone
        { "a lone Paladin holds no slot", "A", "-", {}, settle, "-" },
        -- Forming: A and B both hello with "-", settle, sort by name
        { "forming: the first by name takes Kings", "A", "-", { B = "-" }, settle, "K" },
        { "forming: the second takes Might/Wisdom", "B", "-", { A = "-" }, settle, "MW" },
        { "a lone Paladin in the raid sorts with a newcomer", "A", "-", { B = "-" }, claim("B"), "K" },
        { "two Paladins keep Might/Wisdom", "B", "MW", { A = "K" }, claim("A"), "MW" },
        -- A third joins: Might/Wisdom splits, the holder keeps Wisdom
        { "a newcomer takes the first free slot", "C", "-", { A = "K", B = "MW" }, settle, "M" },
        { "Might/Wisdom's holder keeps Wisdom", "B", "MW", { A = "K", C = "-" }, claim("C"), "W" },
        { "Kings' holder stays put", "A", "K", { B = "MW", C = "-" }, claim("C"), "K" },
        { "a newcomer first by name still takes a free slot", "A", "-", { B = "K", C = "MW" }, settle, "M" },
        -- Fourth and fifth
        { "a fourth takes Light", "D", "-", { A = "K", B = "W", C = "M" }, settle, "L" },
        { "a fifth is a reserve", "E", "-", { A = "K", B = "W", C = "M", D = "L" }, settle, "-" },
        { "a reserve stays one when others come and go", "E", "-", { A = "K", B = "W", C = "M", D = "L" }, claim("D"), "-" },
        -- Leaving with a reserve: the first reserve by name takes the slot
        { "a reserve takes a freed slot", "E", "-", { A = "K", C = "M", D = "L" }, left("B", "W"), "W" },
        { "the first reserve by name takes it", "F", "-", { A = "K", C = "M", D = "L", E = "-" }, left("B", "W"), "-" },
        { "Light's holder stays when a reserve fills the gap", "D", "L", { A = "K", C = "M", E = "-" }, left("B", "W"), "L" },
        { "a reserve leaving moves nobody", "A", "K", { B = "W", C = "M", D = "L" }, left("E", "-"), "K" },
        -- 4 -> 3
        { "Light leaving moves nobody", "C", "M", { A = "K", B = "W" }, left("D", "L"), "M" },
        { "Light's holder fills another gap", "D", "L", { A = "K", C = "M" }, left("B", "W"), "W" },
        -- 3 -> 2
        { "Might leaving: Wisdom becomes Might/Wisdom", "B", "W", { A = "K" }, left("C", "M"), "MW" },
        { "Wisdom leaving: Might becomes Might/Wisdom", "C", "M", { A = "K" }, left("B", "W"), "MW" },
        { "Kings leaving: Might takes Kings", "C", "M", { B = "W" }, left("A", "K"), "K" },
        { "Kings leaving: Wisdom becomes Might/Wisdom", "B", "W", { C = "M" }, left("A", "K"), "MW" },
        -- 2 -> 1
        { "the last one drops coordination", "A", "K", {}, left("B", "MW"), "-" },
        -- Reload: the hello carries the saved slot
        { "a reload keeps a slot nobody else holds", "A", "W", { B = "K", C = "M" }, settle, "W" },
        { "a stale save gives way to the holder", "A", "W", { B = "W", C = "K" }, settle, "M" },
        { "a stale save becomes a reserve when all are taken", "A", "W", { B = "W", C = "K", D = "M", E = "L" }, settle, "-" },
        { "a holder keeps its slot against a hello", "B", "W", { A = "-", C = "K" }, claim("A"), "W" },
        { "a saved slot that no longer exists is dropped", "A", "L", { B = "K", C = "MW" }, settle, "M" },
        -- Two fresh claims of one slot: the first by name keeps it
        { "the first by name keeps a slot two claim", "B", "M", { A = "K", C = "M" }, claim("C"), "M" },
        { "the other takes the first free slot", "C", "M", { A = "K", B = "M" }, claim("B"), "W" },
    }

    for _, row in ipairs(rows) do
        local rule, me, mySlot, peers, event, expected = unpack(row)
        it(rule, function()
            assert.equal(expected, NextSlot(me, mySlot, peers, event))
        end)
    end

    -- The SPEC's worked examples, run from every Paladin's side
    describe("worked examples", function()
        it("A and B form a raid", function()
            assert.equal("K", NextSlot("A", "-", { B = "-" }, settle))
            assert.equal("MW", NextSlot("B", "-", { A = "-" }, settle))
        end)

        it("C joins", function()
            assert.equal("K", NextSlot("A", "K", { B = "MW", C = "-" }, claim("C")))
            assert.equal("W", NextSlot("B", "MW", { A = "K", C = "-" }, claim("C")))
            assert.equal("M", NextSlot("C", "-", { A = "K", B = "MW" }, settle))
        end)

        it("A leaves K/W/M", function()
            assert.equal("K", NextSlot("C", "M", { B = "W" }, left("A", "K")))
            assert.equal("MW", NextSlot("B", "W", { C = "M" }, left("A", "K")))
        end)

        it("A reloads with a stale save", function()
            assert.equal("W", NextSlot("B", "W", { A = "-", C = "K" }, claim("A")))
            assert.equal("M", NextSlot("A", "W", { B = "W", C = "K" }, settle))
        end)
    end)
end)
