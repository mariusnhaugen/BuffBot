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
        group = false,
        raid = false,
        time = 1000,
        printed = {},
        frames = {},
        templates = {},
        categories = {},
        dumped = nil,
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

function State:advance(seconds)
    self.time = self.time + seconds
end

function State:iconOf(name)
    return Spells.iconOf(name)
end

return State
