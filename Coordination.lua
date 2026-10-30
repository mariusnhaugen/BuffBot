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

--------------- MESSAGES ----------------
-- BB:v1:<slot> states the slot a Paladin holds; BB?:v1:<slot> is a hello
-- that everyone answers with their state. Messages carry facts; every client
-- decides its own slot from them with NextSlot.

local VERSION = "1"
local SETTLE = 3 -- seconds to wait for answers to a hello
local ANSWER_DELAY = 2 -- answers go out at random within this many seconds
local VALID_SLOTS = { K = true, W = true, M = true, MW = true, L = true, ["-"] = true }

local active = false -- taking part: a Paladin in a raid, buffing the group, not in PvP
local mySlot = "-"
local peers = {} -- full name -> slot, for the other BuffBot Paladins in the raid
local settling = false -- the player's own hello is waiting for answers
local helloCount = 0 -- so an old hello's settle timer does nothing
local holdUntil = 0 -- blessings wait until then, after a hello
local lastStateAt = -1 -- when the player last sent their state
local answerOwed = false -- a hello came in while the player's own was settling
-- Messages the game refused, such as in combat or when throttled, to send
-- again: after combat, or after RESEND_DELAY out of it
local helloUnsent, stateUnsent = false, false
local resendPending = false
local RESEND_DELAY = 2
local ROSTER_WAIT = 2 -- seconds before a message from outside the roster is tried again

local function PaladinCount()
    local count = 1
    for _ in pairs(peers) do count = count + 1 end
    return count
end

local function Me()
    return GetUnitName("player", true)
end

-- Sends text, and says whether the game took it
local function Send(text)
    local result = select(-1, C_ChatInfo.SendAddonMessage(BuffBot.MESSAGE_PREFIX, text, "RAID"))
    BuffBot.debug("BuffBot sent on RAID:", text, result ~= 0 and ("(failed: " .. tostring(result) .. ")") or "")
    return result == 0
end

local function ScheduleResend()
    if resendPending or InCombatLockdown() then return end
    resendPending = true
    C_Timer.After(RESEND_DELAY, function()
        resendPending = false
        BuffBot.ResendUnsent()
    end)
end

local function SendState()
    lastStateAt = GetTime()
    stateUnsent = not Send("BB:v" .. VERSION .. ":" .. mySlot)
    if stateUnsent then ScheduleResend() end
end

-- The slot is saved per character, so a /reload mid-raid can claim it again
local function SetSlot(slot)
    if slot == mySlot then return end
    mySlot = slot
    BuffBot.charConfig.SLOT = slot ~= "-" and slot or nil
    SendState()
end

local function HoldBlessings()
    holdUntil = GetTime() + SETTLE
    C_Timer.After(SETTLE, BuffBot.CheckPlayerBuffs)
end

-- Ends the player's own hello. Hellos that came in meanwhile get the state
-- now, once, even when the slot didn't change.
local function Settle(count)
    if count ~= helloCount or not active then return end
    settling = false
    local sentBefore = lastStateAt
    SetSlot(BuffBot.NextSlot(Me(), mySlot, peers, { kind = "settle" }))
    if answerOwed and lastStateAt == sentBefore then SendState() end
    answerOwed = false
end

local function SendHello()
    settling = true
    helloCount = helloCount + 1
    local count = helloCount
    helloUnsent = not Send("BB?:v" .. VERSION .. ":" .. mySlot)
    if helloUnsent then ScheduleResend() end
    HoldBlessings()
    C_Timer.After(SETTLE, function()
        Settle(count)
        BuffBot.CheckPlayerBuffs()
    end)
end

-- Applies an event unless the player's own hello is still settling, which
-- covers it when it ends
local function Recompute(event)
    if settling then return end
    SetSlot(BuffBot.NextSlot(Me(), mySlot, peers, event))
end

-- The raid unit of a full name, or nil
local function RaidUnit(name)
    for i = 1, GetNumGroupMembers() do
        local unit = "raid" .. i
        if GetUnitName(unit, true) == name then return unit end
    end
end

local function CanTakePart()
    return BuffBot.playerclass == "PALADIN" and IsInRaid() and BuffBot.config.GROUP_BUFFING
        and not BuffBot.InPvP()
end

-- Stops taking part. Still in the raid, it says goodbye, so the others free
-- the player's slot as if they'd left.
local function Reset()
    if IsInRaid() then Send("BB!:v" .. VERSION .. ":-") end
    active, mySlot, peers, settling, holdUntil, answerOwed = false, "-", {}, false, 0, false
    helloUnsent, stateUnsent = false, false
    BuffBot.charConfig.SLOT = nil
end

-- Starts or stops taking part, and drops Paladins who left the raid or went
-- offline. Runs on roster, connection and settings changes.
function BuffBot.UpdateCoordination()
    if not CanTakePart() then
        if active then Reset() end
        return
    end
    if not active then
        -- After a /reload, the hello claims the saved slot back
        active, mySlot = true, BuffBot.charConfig.SLOT or "-"
        SendHello()
        return
    end
    for name, slot in pairs(peers) do
        local unit = RaidUnit(name)
        if not unit or not UnitIsConnected(unit) then
            peers[name] = nil
            Recompute({ kind = "peerLeft", name = name, slot = slot })
        end
    end
end

-- Another slot holder than sender, by full name
local function HeldByOther(slot, sender)
    if slot == "-" then return false end
    if mySlot == slot then return true end
    for name, peerSlot in pairs(peers) do
        if name ~= sender and peerSlot == slot then return true end
    end
    return false
end

-- Frees a Paladin's slot as if they'd left the raid
local function Drop(name)
    local oldSlot = peers[name]
    if not oldSlot then return end
    peers[name] = nil
    Recompute({ kind = "peerLeft", name = name, slot = oldSlot })
end

-- BB!:v1:- is a goodbye from a Paladin who stopped buffing the group
function BuffBot.OnAddonMessage(text, sender, retried)
    if not active or sender == Me() then return end
    if not RaidUnit(sender) then
        -- The roster may not show a Paladin who has just joined yet
        if not retried then
            C_Timer.After(ROSTER_WAIT, function() BuffBot.OnAddonMessage(text, sender, true) end)
        end
        return
    end
    local kind, version, slot = text:match("^(BB[%?!]?):v(%d+):(%S+)$")
    if not kind then return end
    if version ~= VERSION or not VALID_SLOTS[slot] or kind == "BB!" then
        -- A goodbye, or another version (an outsider): no slot here
        return Drop(sender)
    end

    if kind == "BB?" then
        -- A hello's slot only counts if nobody else holds it
        peers[sender] = HeldByOther(slot, sender) and "-" or slot
        local heardAt = GetTime()
        C_Timer.After(math.random() * ANSWER_DELAY, function()
            if not active or lastStateAt >= heardAt then return end
            -- While settling, the slot may still change: answer at the settle
            if settling then
                answerOwed = true
            else
                SendState()
            end
        end)
        HoldBlessings()
    else
        peers[sender] = slot
    end
    Recompute({ kind = "claim", name = sender })
    -- A claim on the player's slot that the player keeps: say so, so the
    -- other gives way. They may have missed or dropped the player.
    if kind == "BB" and not settling and mySlot ~= "-" and Normalize(slot, PaladinCount()) == mySlot then
        SendState()
    end
    BuffBot.CheckPlayerBuffs()
end

-- Sends what the game refused again: a lost hello as a new hello, which
-- carries the slot so it stands in for a lost state too, or else the state
-- as it is now. A refused resend is retried in turn.
function BuffBot.ResendUnsent()
    if not active then return end
    if helloUnsent then
        stateUnsent = false
        SendHello()
    elseif stateUnsent then
        SendState()
    end
end

-- Whether blessings should wait for a hello's answers
function BuffBot.BlessingsOnHold()
    return active and GetTime() < holdUntil
end

-- The player's slot, "-" for none
function BuffBot.MySlot()
    return mySlot
end

-- Logging in starts without a slot: going offline already gave it up. A
-- /reload keeps the saved one.
function BuffBot.EnteredWorld(isInitialLogin)
    if isInitialLogin then BuffBot.charConfig.SLOT = nil end
end

-- The slots the other BuffBot Paladins in the raid hold
function BuffBot.OtherSlots()
    local slots = {}
    for _, slot in pairs(peers) do
        if slot ~= "-" then table.insert(slots, slot) end
    end
    return slots
end

local SLOT_NAMES = { K = "Kings", MW = "Might/Wisdom", W = "Wisdom", M = "Might", L = "Light", ["-"] = "reserve" }
local ROLE_ORDER = { "tank", "melee", "ranged", "caster", "healer" }

-- /bb raid: who gives which blessing, the Paladins outside BuffBot, and every
-- member's role with where it came from (none for the class default)
function BuffBot.RaidCommand()
    if not IsInRaid() then return print("BuffBot: not in a raid.") end
    local me = Me()

    if active then
        local paladins = { me .. " " .. (next(peers) and SLOT_NAMES[mySlot] or "alone") .. " (you)" }
        local names = {}
        for name in pairs(peers) do table.insert(names, name) end
        table.sort(names)
        for _, name in ipairs(names) do table.insert(paladins, name .. " " .. SLOT_NAMES[peers[name]]) end
        print("BuffBot Paladins: " .. table.concat(paladins, ", "))
    end

    local outsiders, byRole = {}, {}
    for i = 1, GetNumGroupMembers() do
        local unit = "raid" .. i
        local name = GetUnitName(unit, true)
        if name and name ~= me and select(2, UnitClass(unit)) == "PALADIN" and not peers[name] then
            table.insert(outsiders, name)
        end
        local role, source = BuffBot.RoleOf(unit)
        if name and role then
            byRole[role] = byRole[role] or {}
            table.insert(byRole[role], source == "class" and name or (name .. " (" .. source .. ")"))
        end
    end
    if active and #outsiders > 0 then
        table.sort(outsiders)
        print("Not on BuffBot: " .. table.concat(outsiders, ", "))
    end
    for _, role in ipairs(ROLE_ORDER) do
        if byRole[role] then print(role .. ": " .. table.concat(byRole[role], ", ")) end
    end
    local waiting = BuffBot.InspectsWaiting()
    if waiting > 0 then print(waiting .. " waiting for Inspect.") end
end

-- Whether a unit is in the raid and not a BuffBot Paladin sharing out slots
-- with the player
function BuffBot.IsOutsider(unit)
    local name = unit and GetUnitName(unit, true)
    return name ~= nil and name ~= Me() and RaidUnit(name) ~= nil and not peers[name]
end

-- Whether other BuffBot Paladins in the raid share out blessings with the player
function BuffBot.Coordinating()
    return active and next(peers) ~= nil
end
