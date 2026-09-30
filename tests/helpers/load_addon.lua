-- Loads the addon into a fresh sandbox per test, the way the client does:
-- files in TOC order, each called with (addonName, namespace).
local State = require("mocks.state")
local Spells = require("mocks.spells")

local ADDON_NAME = "BuffBot"

local function tocFiles(path)
    local files = {}
    for line in io.lines(path) do
        line = line:gsub("\r$", ""):match("^%s*(.-)%s*$")
        if line ~= "" and not line:match("^#") then
            table.insert(files, line)
        end
    end
    return files
end

local Harness = {}
Harness.__index = Harness

function Harness:fire(event, ...)
    for _, frame in ipairs(self.state.frames) do
        local onEvent = frame:GetScript("OnEvent")
        if frame.events[event] and onEvent then
            onEvent(frame, event, ...)
        end
    end
end

function Harness:slash(arg)
    self.env.SlashCmdList.BUFFBOTSETTINGS(arg or "")
end

-- State changes, each followed by the event the client would fire.
function Harness:refresh()
    self:fire("UNIT_AURA", "player", {})
end

function Harness:give(name, opts)
    self.state:giveAura(name, opts)
    self:refresh()
end

function Harness:remove(name)
    self.state:removeAura(name)
    self:fire("UNIT_AURA", "player", { removedAuraInstanceIDs = { 1 } })
end

function Harness:learn(...)
    self.state:learn(...)
    self:fire("SPELLS_CHANGED")
end

function Harness:enterCombat()
    self.state.combat = true
    self:fire("PLAYER_REGEN_DISABLED")
end

function Harness:leaveCombat()
    self.state.combat = false
    self:fire("PLAYER_REGEN_ENABLED")
end

function Harness:joinRaid()
    self.state.group, self.state.raid = true, true
    self:fire("GROUP_ROSTER_UPDATE")
end

function Harness:leaveGroup()
    self.state.group, self.state.raid = false, false
    self:fire("GROUP_LEFT")
end

function Harness:cast(name)
    self:fire("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-GUID", assert(Spells.idOf(name), name))
end

function Harness:setting(key, value)
    self.ns.config[key] = value
    self.ns.UpdateClassBuffList()
end

-- Observations
function Harness:shown()
    if not self.button:IsShown() then return nil end
    local macro = self.button:GetAttribute("macrotext1")
    return macro and macro:match("^/cast %[target=player%](.+)$")
end

function Harness:suggestions()
    local texts = {}
    for _, fs in ipairs(self.ns.suggestionList or {}) do
        if fs:IsShown() then table.insert(texts, fs:GetText()) end
    end
    return texts
end

-- Presses the button until nothing is left, returning the buffs in cast order.
function Harness:buffUp()
    local cast = {}
    for _ = 1, 20 do
        local buff = self:shown()
        if not buff then return cast end
        table.insert(cast, buff)
        self:give(buff)
    end
    error("buffUp did not converge: " .. table.concat(cast, ", "))
end

function Harness:printed(pattern)
    for _, line in ipairs(self.state.printed) do
        if line:find(pattern, 1, true) then return true end
    end
    return false
end

local M = {}

-- opts:
--   class   player class token (default WARRIOR)
--   known   list of known spell names
--   saved   BuffBotConfig SavedVariables value before load (default nil)
--   config  config overrides applied after ADDON_LOADED
--   raid    start in a raid
function M.load(opts)
    opts = opts or {}
    local state = State.new(opts.class)
    state:learn(unpack(opts.known or {}))
    if opts.raid then state.group, state.raid = true, true end

    local env = setmetatable({}, { __index = _G })
    env._G = env
    require("mocks.api_common")(state, env)
    require("mocks.api_forever")(state, env)
    env.BuffBotConfig = opts.saved

    local ns = {}
    for _, file in ipairs(tocFiles(ADDON_NAME .. ".toc")) do
        local chunk = assert(loadfile(file))
        setfenv(chunk, env)
        chunk(ADDON_NAME, ns)
    end

    local h = setmetatable({ state = state, env = env, ns = ns, button = ns.macroButton }, Harness)
    h:fire("ADDON_LOADED", ADDON_NAME)
    for key, value in pairs(opts.config or {}) do
        ns.config[key] = value
    end
    h:fire("SPELLS_CHANGED")
    return h
end

return M
