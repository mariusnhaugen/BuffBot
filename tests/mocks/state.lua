-- Fake game state. The API mocks read from this; specs only ever change it
-- through these helpers, never through WoW API calls.
local Spells = require("mocks.spells")

local State = {}
State.__index = State

function State.new(class)
    return setmetatable({
        class = class or "WARRIOR",
        known = {},
        unusable = {},
        auras = {},
        combat = false,
        dead = false,
        ghost = false,
        taxi = false,
        mainHand = 2361, -- equipped main-hand item ID, nil for none
        offHand = nil, -- equipped off-hand item ID
        -- By weapon slot (0 main hand, 1 off hand): { type = 2 or 3, timeLeft = ms, charges }
        weaponEnchants = {},
        bags = {}, -- item ID -> count
        group = false,
        raid = false,
        time = 1000,
        timers = {}, -- { at = time, callback } from C_Timer.After
        printed = {},
        frames = {},
        templates = {},
        categories = {},
        openedCategory = nil,
    }, State)
end

function State:learn(...)
    for _, name in ipairs({ ... }) do
        self.known[name] = true
    end
end

function State:unlearn(name)
    self.known[name] = nil
end

function State:knows(name)
    return self.known[name] == true
end

-- A client in another language. translate maps the English names the specs
-- use to the client's names; the API mocks only accept the client's names.
function State:localName(english)
    return self.translate and self.translate(english) or english
end

function State:englishName(name)
    if not self.translate then return name end
    for _, english in ipairs(Spells.names()) do
        if self.translate(english) == name then return english end
    end
    return nil
end

function State:isUsable(name)
    return self:knows(name) and not self.unusable[name]
end

-- opts: duration (seconds, 0 = permanent), remaining (seconds), fromPlayer (default true)
function State:giveAura(name, opts)
    opts = opts or {}
    local duration = opts.duration or 1800
    local remaining = opts.remaining or duration
    self.auras[name] = {
        name = name,
        spellId = Spells.idOf(name),
        duration = duration,
        expirationTime = duration > 0 and (self.time + remaining) or 0,
        isFromPlayerOrPlayerPet = opts.fromPlayer ~= false,
    }
end

function State:removeAura(name)
    self.auras[name] = nil
end

-- Moves the clock on and runs the timers that came due, in order
function State:advance(seconds)
    self.time = self.time + seconds
    table.sort(self.timers, function(a, b) return a.at < b.at end)
    while self.timers[1] and self.timers[1].at <= self.time do
        table.remove(self.timers, 1).callback()
    end
end

function State:iconOf(name)
    return Spells.iconOf(name)
end

return State
