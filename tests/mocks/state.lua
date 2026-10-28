-- Fake game state. The API mocks read from this; specs only ever change it
-- through these helpers, never through WoW API calls.
local Spells = require("mocks.spells")

local State = {}
State.__index = State

-- A unique value that the issecretvalue mock reports as secret
State.SECRET = setmetatable({}, { __tostring = function() return "<secret>" end })

function State.new(class)
    return setmetatable({
        class = class or "WARRIOR",
        playerName = "Tester", -- the player's full name, "First Last" on Forever
        known = {},
        locale = "enUS",
        talents = {}, -- points spent per talent tree, by tab
        unusable = {},
        auras = {},
        combat = false,
        dead = false,
        ghost = false,
        taxi = false,
        instanceType = "none", -- "pvp" in a battleground
        casting = false, -- mid-cast, so a cast now fails
        gcdUntil = 0, -- time the global cooldown ends
        casts = {}, -- spell names from CastSpellByID, including failed casts
        mainHand = 2361, -- equipped main-hand item ID, nil for none
        offHand = nil, -- equipped off-hand item ID
        -- By weapon slot (0 main hand, 1 off hand): { type = 2 or 3, timeLeft = ms, charges }
        weaponEnchants = {},
        bags = {}, -- item ID -> count
        group = false,
        raid = false,
        -- Other group members by unit ("party1", or "raid2" on: the player is
        -- raid1): { name, class, subgroup, dead, offline, visible, inRange, auras }
        members = {},
        playerSubgroup = 1,
        time = 1000,
        timers = {}, -- { at = time, callback } from C_Timer.After
        printed = {},
        inspects = {}, -- units passed to NotifyInspect, in order
        inspecting = nil, -- the unit being inspected
        prefixes = {}, -- add-on message prefixes registered
        sent = {}, -- { prefix, text, chatType } for each add-on message that went out
        sendResult = nil, -- forces SendAddonMessage's result when set
        random = nil, -- replaces math.random when set
        frames = {},
        templates = {},
        categories = {},
        settings = {}, -- label -> setting
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

-- The player's own unit in a raid
function State:resolve(unit)
    if self.raid and unit == "raid1" then return "player" end
    return unit
end

-- A unit's aura table, or nil for a unit that isn't there
function State:aurasOf(unit)
    unit = self:resolve(unit)
    if unit == "player" then return self.auras end
    local member = self.members[unit]
    return member and member.auras
end

-- opts: duration (seconds, 0 = permanent), remaining (seconds), fromPlayer
-- (default true), source (the caster's unit when not the player, default
-- nil), unit (default player)
function State:giveAura(name, opts)
    opts = opts or {}
    local duration = opts.duration or 1800
    local remaining = opts.remaining or duration
    self:aurasOf(opts.unit or "player")[name] = {
        name = name,
        spellId = Spells.idOf(name),
        duration = duration,
        expirationTime = duration > 0 and (self.time + remaining) or 0,
        isFromPlayerOrPlayerPet = opts.fromPlayer ~= false,
        sourceUnit = opts.fromPlayer ~= false and "player" or opts.source,
    }
end

function State:removeAura(name, unit)
    self:aurasOf(unit or "player")[name] = nil
end

-- Units in the same subgroup as unit, the player included
function State:subgroupOf(unit)
    unit = self:resolve(unit)
    local subgroup = unit == "player" and self.playerSubgroup or self.members[unit].subgroup
    local units = {}
    if not self.raid or subgroup == self.playerSubgroup then table.insert(units, "player") end
    for other, member in pairs(self.members) do
        if not self.raid or member.subgroup == subgroup then table.insert(units, other) end
    end
    return units
end

-- Group members of the same class as unit, the player included
function State:classmatesOf(unit)
    unit = self:resolve(unit)
    local class = unit == "player" and self.class or self.members[unit].class
    local units = {}
    if class == self.class then table.insert(units, "player") end
    for other, member in pairs(self.members) do
        if member.class == class then table.insert(units, other) end
    end
    table.sort(units)
    return units
end

-- Moves the clock on and runs the timers that came due, in order, each at
-- its own time, including timers they start
function State:advance(seconds)
    local target = self.time + seconds
    while true do
        table.sort(self.timers, function(a, b) return a.at < b.at end)
        local timer = self.timers[1]
        if not timer or timer.at > target then break end
        table.remove(self.timers, 1)
        self.time = math.max(self.time, timer.at)
        timer.callback()
    end
    self.time = target
end

function State:iconOf(name)
    return Spells.iconOf(name)
end

return State
