local _, BuffBot = ...

local class = BuffBot.playerclass
local REMINDER_DURA_MULTIPLIER = 0.2 -- aura.Duration * REMINDER_DURA_MULTIPLIER to get reminder duration

--------------- MAIN FUNCTIONS ----------------

local RANGE_POLL = 2 -- seconds between range re-checks in a group

local polling = false
local function PollRange()
    polling = false
    if InCombatLockdown() then return end
    BuffBot.CheckPlayerBuffs()
end

-- No event says a member came into spell range, so re-check every few seconds
-- while a member in view is missing a buff and out of range. Members out of
-- view are left to the UNIT_AURA they fire on coming into view. Stops on its
-- own.
local function StartRangePoll()
    if polling then return end
    polling = true
    C_Timer.After(RANGE_POLL, PollRange)
end

function BuffBot.UpdateClassBuffList()
    BuffBot.debug("UpdateClassBuffList")
    BuffBot.FilterInitialList()
    BuffBot.CheckPlayerBuffs()
end

function BuffBot.HasUniqueClassBuff()
    for i = 1, #BuffBot.uniqueBuffs, 1 do
        if BuffBot.UnitHasAssignedBuff("player", BuffBot.uniqueBuffs[i]) then
            return true
        end
    end
    return false
end

local function ShouldBloodrageFirst(buffString)
    if class ~= "WARRIOR" or buffString ~= "Battle Shout" then return false end
    return BuffBot.config.BLOODRAGE and BuffBot.CheckSpellAvailable("Bloodrage")
end

local INVSLOT_MAINHAND = 16

local function ShouldSkipBuff(buffString)
    -- An imbue needs a main-hand weapon
    if BuffBot.WeaponImbues[buffString] and not GetInventoryItemID("player", INVSLOT_MAINHAND) then
        return true
    end
    -- A poison needs a weapon in that hand and a poison in the bags
    local poison = BuffBot.WeaponPoisons[buffString]
    if poison and not (GetInventoryItemID("player", poison.invSlot) and BuffBot.PoisonItem(buffString)) then
        return true
    end
    if BuffBot.IndexOf(buffString, BuffBot.uniqueBuffs) and BuffBot.HasUniqueClassBuff() then
        return true -- check auras and armors
    end
end

-- Missing the buff and any group version of it
local function UnitMissing(unit, buffString)
    if BuffBot.UnitHasAssignedBuff(unit, buffString) then return false end
    for _, groupVersion in ipairs(BuffBot.GroupVersions[buffString] or {}) do
        if BuffBot.UnitHasAssignedBuff(unit, groupVersion) then return false end
    end
    return true
end

-- A member the buff would help, alive and in view. The class check comes
-- first, so classes the buff does nothing for never cost an aura or range
-- check.
local function CanSeeUnit(unit, buffString)
    if unit == "player" then return true end
    local skip = BuffBot.SkipOnClass[buffString]
    if skip and skip[select(2, UnitClass(unit))] then return false end
    return UnitExists(unit) and UnitIsConnected(unit) and UnitIsVisible(unit)
        and not UnitIsDeadOrGhost(unit)
end

local function InRange(unit, buffString)
    return unit == "player" or C_Spell.IsSpellInRange(BuffBot.SpellName(buffString), unit) == true
end

-- The units to buff, as subgroups: the player's own first, starting with the
-- player, then the rest of the raid when that's turned on. Pets can't be
-- buffed in Forever.
local function GroupUnits()
    if not BuffBot.config.GROUP_BUFFING or not IsInGroup() then return { { "player" } } end
    if not IsInRaid() then
        local party = { "player" }
        for i = 1, GetNumSubgroupMembers() do
            table.insert(party, "party" .. i)
        end
        return { party }
    end
    local subgroups, own = {}, 1
    for i = 1, GetNumGroupMembers() do
        local unit = "raid" .. i
        local subgroup = select(3, GetRaidRosterInfo(i)) or 1
        subgroups[subgroup] = subgroups[subgroup] or {}
        if UnitIsUnit(unit, "player") then
            own = subgroup
            table.insert(subgroups[subgroup], 1, "player")
        else
            table.insert(subgroups[subgroup], unit)
        end
    end
    local ordered = { subgroups[own] or { "player" } }
    if BuffBot.config.RAID_BUFFING then
        for subgroup = 1, 8 do
            if subgroup ~= own and subgroups[subgroup] then
                table.insert(ordered, subgroups[subgroup])
            end
        end
    end
    return ordered
end

-- The buff a member gets: a blessing picked by their class, otherwise the
-- player's own. nil when that blessing isn't learned yet.
local function BuffForUnit(buffString, unit)
    if unit == "player" or not BuffBot.Blessings[buffString] then return buffString end
    local blessing = BuffBot.BlessingFor(unit)
    if blessing == buffString or BuffBot.CheckSpellAvailable(blessing) then return blessing end
end

-- One subgroup's entries for a group buff: the group version when two or
-- more who'd benefit are missing it and it can be cast, else one per member.
-- Blessings are always single-target. True when a member in view is missing
-- it out of range.
local function AddGroupBuff(missing, buffString, units)
    local targets, outOfRange = {}, false
    for _, unit in ipairs(units) do
        local buff = BuffForUnit(buffString, unit)
        if buff and CanSeeUnit(unit, buff) and UnitMissing(unit, buff) then
            if InRange(unit, buff) then
                table.insert(targets, { buff = buff, unit = unit })
            else
                outOfRange = true
            end
        end
    end
    local groupVersion = #targets >= 2 and not BuffBot.Blessings[buffString]
        and BuffBot.CastableGroupVersion(buffString)
    if groupVersion then
        table.insert(missing, { buff = groupVersion, unit = targets[1].unit })
        return outOfRange
    end
    for _, target in ipairs(targets) do
        table.insert(missing, target)
    end
    return outOfRange
end

-- Every cast the button would make, in order, as { buff, unit } entries. The
-- button casts the first, and the suggestion list shows them all. A group
-- buff goes on everyone before the next buff starts. The second result is
-- true when a member in view is missing a buff out of range.
function BuffBot.MissingBuffs()
    local missing = {}
    if InCombatLockdown() then return missing end
    if UnitIsDeadOrGhost("player") or UnitOnTaxi("player") then return missing end
    local classBuffs = BuffBot.classBuffList
    if classBuffs == nil then return missing end

    local subgroups, outOfRange = GroupUnits(), false
    for i = 1, #classBuffs do
        local currentBuff = classBuffs[i]
        if BuffBot.GroupBuffs[currentBuff] then
            for _, units in ipairs(subgroups) do
                outOfRange = AddGroupBuff(missing, currentBuff, units) or outOfRange
            end
        elseif not ShouldSkipBuff(currentBuff) and UnitMissing("player", currentBuff) then
            table.insert(missing, { buff = currentBuff, unit = "player" })
        end
    end
    return missing, outOfRange
end

-- The last entry logged, so the range poll doesn't repeat it every few seconds
local lastLogged

function BuffBot.CheckPlayerBuffs()
    local missing, outOfRange = BuffBot.MissingBuffs()
    if outOfRange then StartRangePoll() end
    local entry = missing[1]
    if not entry then
        lastLogged = nil
        if InCombatLockdown() then return end
        BuffBot.macroButton:Hide()
        return
    end
    local buff = entry.buff
    if lastLogged ~= buff .. entry.unit then
        lastLogged = buff .. entry.unit
        BuffBot.debug(buff, " Missing on ", entry.unit)
    end
    local poison = BuffBot.WeaponPoisons[buff]
    if poison then
        BuffBot.UpdateItemMacro(BuffBot.PoisonItem(buff), poison.invSlot)
    else
        BuffBot.UpdateMacro(buff, entry.unit, ShouldBloodrageFirst(buff) and "Bloodrage" or nil)
    end

    BuffBot.UpdateSuggestionList(missing)
end

local WEAPON_MAINHAND = 0                     --0,1,2 are mh,oh,ranged
local ENCHANT_TEMPORARY, ENCHANT_IMBUE = 2, 3 --enchantType
local LOW_CHARGES = 10

-- Any temporary enchant counts, so an rsham oil isn't overwritten with an imbue.
function BuffBot.HasWeaponEnchant(weaponSlot)
    for _, enchant in ipairs(C_Item.GetWeaponEnchantInfo(weaponSlot or WEAPON_MAINHAND) or {}) do
        local temporary = enchant.enchantType == ENCHANT_TEMPORARY or enchant.enchantType == ENCHANT_IMBUE
        -- Expiring like a buff: under 5 minutes left (timeLeft is in ms), or
        -- low on charges. Enchants without charges report 0.
        local expiring = enchant.timeLeft < 300000 or (enchant.charges > 0 and enchant.charges < LOW_CHARGES)
        if enchant.hasEnchant and temporary and not expiring then
            return true
        end
    end
    return false
end

function BuffBot.UnitHasAssignedBuff(unit, buffString)
    if buffString == "" then return end
    if BuffBot.WeaponImbues[buffString] then
        return unit == "player" and BuffBot.HasWeaponEnchant()
    end
    local poison = BuffBot.WeaponPoisons[buffString]
    if poison then
        return unit == "player" and BuffBot.HasWeaponEnchant(poison.weaponSlot)
    end

    local filter = BuffBot.OwnOnlyBuffs[buffString] and "HELPFUL|PLAYER" or nil
    local aura = C_UnitAuras.GetAuraDataBySpellName(unit, BuffBot.SpellName(buffString), filter)
    if aura ~= nil then
        -- Only the player's own buffs are refreshed early. Someone else's
        -- counts until it drops off, since refreshing it is their job.
        if aura.sourceUnit == "player" and (aura.duration > 0) and (aura.expirationTime > 0) then
            local timeLeft = aura.expirationTime - GetTime()
            if (timeLeft < aura.duration * REMINDER_DURA_MULTIPLIER) and (timeLeft < 300) then
                return false
            end
        end
        return true
    else
        return false
    end
end
