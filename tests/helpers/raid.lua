-- Several BuffBot clients in one raid: a real sandbox per Paladin, one
-- roster, one clock, and a bus that delivers each RAID add-on message to
-- every client on the next tick. For specs that every client agrees on the
-- slots (docs/plan/SPEC.md, test strategy).
local Addon = require("helpers.load_addon")

local TICK = 0.1

local Raid = {}
Raid.__index = Raid

local KNOWN = { "Blessing of Might", "Blessing of Wisdom", "Blessing of Kings", "Blessing of Light" }

function Raid.new()
    return setmetatable({ clients = {}, order = {}, queue = {}, dropped = 0, offline = {} }, Raid)
end

-- Each client's roster: every other client, as Paladins in subgroup 1
function Raid:updateRosters()
    for _, name in ipairs(self.order) do
        local members = {}
        for _, other in ipairs(self.order) do
            if other ~= name then
                table.insert(members, { class = "PALADIN", name = other, offline = self.offline[other] })
            end
        end
        self.clients[name]:joinRaid(members)
    end
end

-- Sends go on the bus when the game accepts them
function Raid:connect(name, h)
    local send = h.env.C_ChatInfo.SendAddonMessage
    h.env.C_ChatInfo.SendAddonMessage = function(prefix, text, chatType)
        local queued, result = send(prefix, text, chatType)
        if result == 0 then
            table.insert(self.queue, { sender = name, text = text })
        elseif result == 3 then
            self.dropped = self.dropped + 1
        end
        return queued, result
    end
end

-- A client with its own answer delay, so clients don't answer in lockstep
function Raid:load(name, charSaved)
    local h = Addon.load({ class = "PALADIN", known = KNOWN, name = name, charSaved = charSaved })
    local delay = (#self.order * 0.37 + 0.1) % 1
    h.state.random = function() return delay end
    self:connect(name, h)
    return h
end

-- Paladins joining together: each one's roster changes at the same moment
function Raid:join(...)
    for _, name in ipairs({ ... }) do
        self.clients[name] = self:load(name)
        table.insert(self.order, name)
    end
    self:updateRosters()
end

function Raid:leave(name)
    self.clients[name] = nil
    for i, other in ipairs(self.order) do
        if other == name then table.remove(self.order, i) end
    end
    self:updateRosters()
end

-- Offline: still on the roster, but the client sends and hears nothing
function Raid:goOffline(name)
    self.offline[name] = true
    for _, other in ipairs(self.order) do
        if other ~= name then
            local h = self.clients[other]
            for unit, member in pairs(h.state.members) do
                if member.name == name then
                    member.offline = true
                    h:fire("UNIT_CONNECTION", unit)
                end
            end
        end
    end
end

-- A /reload: a fresh client with the old one's saved settings
function Raid:reload(name)
    local saved = self.clients[name].ns.charConfig
    local h = self:load(name, { TRACKER = saved.TRACKER, SLOT = saved.SLOT })
    h:fire("PLAYER_ENTERING_WORLD", false, true)
    self.clients[name] = h
    self:updateRosters()
end

-- Moves every client's clock on together, delivering messages a tick after
-- they're sent
function Raid:run(seconds)
    for _ = 1, math.floor(seconds / TICK + 0.5) do
        local queue = self.queue
        self.queue = {}
        for _, message in ipairs(queue) do
            for _, name in ipairs(self.order) do
                if not self.offline[name] and not self.offline[message.sender] then
                    self.clients[name]:receive(message.sender, message.text)
                end
            end
        end
        for _, name in ipairs(self.order) do
            self.clients[name].state:advance(TICK)
        end
    end
end

-- Every online client's own slot, by name
function Raid:slots()
    local slots = {}
    for _, name in ipairs(self.order) do
        if not self.offline[name] then slots[name] = self.clients[name].ns.MySlot() end
    end
    return slots
end

-- Each online client's view of the others' slots, sorted, by name
function Raid:views()
    local views = {}
    for _, name in ipairs(self.order) do
        if not self.offline[name] then
            local view = self.clients[name].ns.OtherSlots()
            table.sort(view)
            views[name] = view
        end
    end
    return views
end

return Raid
