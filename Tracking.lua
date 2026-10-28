local _, BuffBot = ...

-- Tracking is cast by the add-on itself, not the button: CastSpellByID works
-- for tracking without a key press (see PROBE_RESULTS.md).

-- What the Tracking dropdown offers, in order. Only one can be on at a time.
BuffBot.Trackers = { "Find Minerals", "Find Herbs", "Track Beasts", "Track Humanoids", "Track Undead",
    "Track Hidden", "Track Elementals", "Track Demons", "Track Giants", "Track Dragonkin" }

-- Used until the player picks a tracker
local DEFAULT_ORDER = { "Find Minerals", "Find Herbs", "Track Beasts" }

-- The Dwarf racial, which stacks with the other trackers on Forever
local TREASURE = "Find Treasure"

local RETRY_DELAY = 0.5
local GIVE_UP_AFTER = 10

function BuffBot.KnowsTracker(key)
    local spellID = BuffBot.SpellID(key)
    return spellID ~= nil and IsPlayerSpell(spellID)
end

local function IsOn(key)
    return BuffBot.UnitHasAssignedBuff("player", key)
end

function BuffBot.DefaultTracker()
    for _, key in ipairs(DEFAULT_ORDER) do
        if BuffBot.KnowsTracker(key) then return key end
    end
end

-- The tracker to keep on, or nil for none. A saved tracker the character no
-- longer knows falls back to the default.
function BuffBot.ChosenTracker()
    local saved = BuffBot.charConfig.TRACKER
    if saved == "Off" then return nil end
    if saved ~= "" and BuffBot.KnowsTracker(saved) then return saved end
    return BuffBot.DefaultTracker()
end

-- The trackers to cast, in order. Any known tracker already on is left alone,
-- unless the player just picked another one (switchTo).
local function MissingTrackers(switchTo)
    local missing = {}
    if switchTo then
        if not IsOn(switchTo) then table.insert(missing, switchTo) end
    else
        local anyOn = false
        for _, key in ipairs(BuffBot.Trackers) do
            if BuffBot.KnowsTracker(key) and IsOn(key) then anyOn = true end
        end
        local chosen = BuffBot.ChosenTracker()
        if chosen and not anyOn then table.insert(missing, chosen) end
    end
    if BuffBot.config.TRACK_TREASURE and BuffBot.KnowsTracker(TREASURE) and not IsOn(TREASURE) then
        table.insert(missing, TREASURE)
    end
    return missing
end

-- Seconds until a cast can work: the GCD left, or a retry while the player
-- is casting. A cast during either fails with an error.
local function BusyFor(key)
    local cooldown = C_Spell.GetSpellCooldown(BuffBot.SpellID(key))
    local left = cooldown and (cooldown.startTime + cooldown.duration - GetTime()) or 0
    if UnitCastingInfo("player") or UnitChannelInfo("player") then
        left = math.max(left, RETRY_DELAY)
    end
    return left
end

-- Each call starts a new loop, and older loops stop at their next step
local generation = 0
local resumeAfterCombat

-- Casts the missing trackers one at a time, waiting out the GCD between them,
-- and gives up after GIVE_UP_AFTER seconds. Waits for the end of combat, so
-- it never takes a GCD mid-fight.
function BuffBot.UpdateTracking(switchTo)
    resumeAfterCombat = nil
    if BuffBot.InPvP() then return end
    generation = generation + 1
    local loop = generation
    local deadline = GetTime() + GIVE_UP_AFTER

    local function step()
        if loop ~= generation then return end
        if BuffBot.InPvP() or UnitIsDeadOrGhost("player") or GetTime() > deadline then return end
        if InCombatLockdown() then
            resumeAfterCombat = function() BuffBot.UpdateTracking(switchTo) end
            return
        end
        local key = MissingTrackers(switchTo)[1]
        if not key then return end
        local wait = BusyFor(key)
        if wait > 0 then
            C_Timer.After(math.max(wait, RETRY_DELAY), step)
            return
        end
        BuffBot.debug("Tracking ", key)
        CastSpellByID(BuffBot.SpellID(key))
        C_Timer.After(RETRY_DELAY, step)
    end
    step()
end

function BuffBot.ResumeTracking()
    local resume = resumeAfterCombat
    resumeAfterCombat = nil
    if resume then resume() end
end

-- Runs the loop when a tracker is learned, which includes the first
-- SPELLS_CHANGED after login
local knownTrackers = {}
function BuffBot.TrackingSpellsChanged()
    local learned = false
    local function check(key)
        local knows = BuffBot.KnowsTracker(key)
        if knows and not knownTrackers[key] then learned = true end
        knownTrackers[key] = knows
    end
    for _, key in ipairs(BuffBot.Trackers) do check(key) end
    check(TREASURE)
    if learned then BuffBot.UpdateTracking() end
end
