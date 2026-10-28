local _, BuffBot = ...

-- Slots: one blessing per BuffBot Paladin for the whole raid
-- (docs/plan/SPEC.md). K Kings, MW Might or Wisdom by role, W Wisdom,
-- M Might, L Light, "-" none (alone, or a reserve once all are taken).
local SLOTS = {
    [2] = { "K", "MW" },
    [3] = { "K", "W", "M" },
    [4] = { "K", "W", "M", "L" },
}

local function SlotsFor(count)
    if count < 2 then return {} end
    return SLOTS[math.min(count, 4)]
end

-- A slot as it reads with count Paladins: Might/Wisdom's holder keeps Wisdom
-- once a third Paladin takes Might
local function Normalize(slot, count)
    if slot == "MW" and count >= 3 then return "W" end
    return slot
end

local function SortedNames(me, peers)
    local names = { me }
    for name in pairs(peers) do table.insert(names, name) end
    table.sort(names)
    return names
end

-- The slot name sort gives the player when they hold none: the Paladins
-- without one take the free slots in order, by name. Holders keep theirs; when
-- two hold the same, the first by name does.
local function Fill(me, peers, count)
    local all = { [me] = "-" }
    for name, slot in pairs(peers) do all[name] = Normalize(slot, count) end
    local valid = {}
    for _, slot in ipairs(SlotsFor(count)) do valid[slot] = true end

    local held, unslotted = {}, {}
    for _, name in ipairs(SortedNames(me, peers)) do
        local slot = all[name]
        if valid[slot] and not held[slot] then
            held[slot] = true
        else
            table.insert(unslotted, name)
        end
    end
    local free = {}
    for _, slot in ipairs(SlotsFor(count)) do
        if not held[slot] then table.insert(free, slot) end
    end
    return free[BuffBot.IndexOf(me, unslotted)] or "-"
end

-- The slot that a Paladin leaving frees goes to the first reserve by name.
-- Without a reserve, the slots close up: Light's holder fills a gap when 4
-- become 3, and Might and Wisdom merge back into MW when 3 become 2, Might's
-- holder taking Kings if that's the gap.
local function AfterLeaving(me, mySlot, peers, freed, count)
    if freed == "-" then return mySlot end
    local reserves = {}
    for _, name in ipairs(SortedNames(me, peers)) do
        local slot = name == me and mySlot or peers[name]
        if slot == "-" then table.insert(reserves, name) end
    end
    if #reserves > 0 then
        return reserves[1] == me and freed or mySlot
    end
    if count == 3 then
        return mySlot == "L" and freed ~= "L" and freed or mySlot
    end
    if count == 2 then
        if freed == "K" then
            return ({ M = "K", W = "MW" })[mySlot] or mySlot
        end
        if (freed == "M" and mySlot == "W") or (freed == "W" and mySlot == "M") then return "MW" end
    end
    return mySlot
end

-- The player's slot after an event, from what every BuffBot Paladin in the
-- raid has announced. Every client runs the same rules on the same facts, so
-- they agree without negotiating.
--   me     the player's full name
--   mySlot the player's slot now ("-" for none)
--   peers  the other BuffBot Paladins in the raid: full name -> slot
--   event  { kind = "settle" }: the player's own hello has had its answers.
--            A slot someone else holds goes to them.
--          { kind = "claim", name = name }: another Paladin's hello or state
--            changed peers. A slot both hold goes to the first by name.
--          { kind = "peerLeft", name = name, slot = slot }: a Paladin left
--            the raid or went offline, and is no longer in peers.
function BuffBot.NextSlot(me, mySlot, peers, event)
    local count = 1
    for _ in pairs(peers) do count = count + 1 end
    if count < 2 then return "-" end

    if event.kind == "peerLeft" then
        local slot = AfterLeaving(me, mySlot, peers, Normalize(event.slot, count + 1), count)
        return Normalize(slot, count)
    end

    local slot = Normalize(mySlot, count)
    for name, peerSlot in pairs(peers) do
        if slot ~= "-" and Normalize(peerSlot, count) == slot and (event.kind == "settle" or name < me) then
            slot = "-"
        end
    end
    if slot ~= "-" and not BuffBot.IndexOf(slot, SlotsFor(count)) then slot = "-" end
    if slot == "-" then return Fill(me, peers, count) end
    return slot
end
