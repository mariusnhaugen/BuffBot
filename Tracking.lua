local _, BuffBot = ...

-- Tracking is cast by the add-on itself, not the button.

-- What the Tracking dropdown offers, in order. Only one can be on at a time.
BuffBot.Trackers = { "Find Minerals", "Find Herbs", "Track Beasts", "Track Humanoids", "Track Undead",
    "Track Hidden", "Track Elementals", "Track Demons", "Track Giants", "Track Dragonkin" }

-- Used until the player picks a tracker
local DEFAULT_ORDER = { "Find Minerals", "Find Herbs", "Track Beasts" }
local TREASURE = "Find Treasure" --Dwarf. Stacks with profession tracking.

local RETRY_DELAY = 0.5
local GIVE_UP_AFTER = 10

function BuffBot.IsTrackerKnown(trackerName)
    local spellID = BuffBot.SpellID(trackerName)
    return spellID ~= nil and IsPlayerSpell(spellID)
end

local function IsTrackerActive(trackerName)
    return BuffBot.UnitHasAssignedBuff("player", trackerName)
end

function BuffBot.GetDefaultTracker()
    for _, trackerName in ipairs(DEFAULT_ORDER) do
        if BuffBot.IsTrackerKnown(trackerName) then return trackerName end
    end
end

-- Use Settings > default
function BuffBot.GetChosenTracker()
    local saved = BuffBot.charConfig.TRACKER
    if saved == "Off" then return nil end
    if saved ~= "" and BuffBot.IsTrackerKnown(saved) then return saved end
    return BuffBot.GetDefaultTracker()
end

-- The trackers to cast, in order. Any known tracker already on is left alone.
local function GetTrackersToCast(picked)
    local toCast = {}
    if picked then
        if not IsTrackerActive(picked) then table.insert(toCast, picked) end
    else
        local anyActive = false
        for _, trackerName in ipairs(BuffBot.Trackers) do
            if BuffBot.IsTrackerKnown(trackerName) and IsTrackerActive(trackerName) then anyActive = true end
        end
        local chosen = BuffBot.GetChosenTracker()
        if chosen and not anyActive then table.insert(toCast, chosen) end
    end
    if BuffBot.config.TRACK_TREASURE and BuffBot.IsTrackerKnown(TREASURE) and not IsTrackerActive(TREASURE) then
        table.insert(toCast, TREASURE)
    end
    return toCast
end

-- Seconds until a cast can work: the GCD left, or a retry while the player
-- is casting. A cast during either fails with an error.
local function GetSecondsUntilCastable(trackerName)
    local cooldown = C_Spell.GetSpellCooldown(BuffBot.SpellID(trackerName))
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
-- and gives up after GIVE_UP_AFTER seconds. Waits for the end of combat.
-- picked is the tracker the player just chose in the settings, force cast even if another is on.
function BuffBot.CastMissingTrackers(picked)
    resumeAfterCombat = nil
    if BuffBot.InPvP() then return end
    generation = generation + 1
    local thisLoop = generation
    local deadline = GetTime() + GIVE_UP_AFTER

    local function castNextTracker()
        if thisLoop ~= generation then return end
        if BuffBot.InPvP() or UnitIsDeadOrGhost("player") or GetTime() > deadline then return end
        if InCombatLockdown() then
            resumeAfterCombat = function() BuffBot.CastMissingTrackers(picked) end
            return
        end
        local trackerName = GetTrackersToCast(picked)[1]
        if not trackerName then return end
        local wait = GetSecondsUntilCastable(trackerName)
        if wait > 0 then
            C_Timer.After(math.max(wait, RETRY_DELAY), castNextTracker)
            return
        end
        BuffBot.debug("Tracking ", trackerName)
        CastSpellByID(BuffBot.SpellID(trackerName))
        C_Timer.After(RETRY_DELAY, castNextTracker)
    end
    castNextTracker()
end

function BuffBot.ResumeTrackingAfterCombat()
    local resume = resumeAfterCombat
    resumeAfterCombat = nil
    if resume then resume() end
end

-- Casts the missing trackers on login or a new one is learned.
local knownTrackers = {}
function BuffBot.CheckForLearnedTrackers()
    local learned = false
    local function recordKnown(trackerName)
        local known = BuffBot.IsTrackerKnown(trackerName)
        if known and not knownTrackers[trackerName] then learned = true end
        knownTrackers[trackerName] = known
    end
    for _, trackerName in ipairs(BuffBot.Trackers) do recordKnown(trackerName) end
    recordKnown(TREASURE)
    if learned then BuffBot.CastMissingTrackers() end
end
