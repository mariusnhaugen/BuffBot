local _, BuffBot = ...

-- The lists that can be reordered, with each entry on or off, on the Class
-- Buff Order and Paladin Blessings pages (ListsPage.lua). Three kinds:
--   cast: the player's own buffs by class, in the order the button casts them
--   blessing: the blessings a Paladin gives each class, best first. Used in
--     parties and solo.
--   role: the same by raid role. Used in raids.
-- The defaults are BuffBot.CastOrder, BuffBot.BlessingPriority and
-- BuffBot.RoleLists. A list is saved in BuffBot.config only once it differs
-- from its default, as rows of { name = ..., on = ... }. A list nobody has
-- edited keeps following the defaults.

BuffBot.ListSaveKeys = { cast = "CAST_ORDER", blessing = "BLESSING_ORDER", role = "ROLE_ORDER" }

-- The entries of each kind that start off
local function DefaultOff(kind, key, name)
    if kind == "cast" then
        -- Only tanks want the extra threat
        return name == "Righteous Fury"
    end
    -- The blessings the class can't use. A role covers several classes, so
    -- its lists keep the rule when picking (BuffBot.BlessingFor).
    if kind == "blessing" then
        local skip = BuffBot.SkipOnClass[name]
        return skip ~= nil and skip[key] == true
    end
    return BuffBot.RoleListsOff[key] ~= nil and BuffBot.RoleListsOff[key][name] == true
end

local function Defaults(kind)
    if kind == "cast" then return BuffBot.CastOrder end
    if kind == "blessing" then return BuffBot.BlessingPriority end
    return BuffBot.RoleLists
end

function BuffBot.DefaultListRows(kind, key)
    local rows = {}
    for _, name in ipairs(Defaults(kind)[key] or {}) do
        table.insert(rows, { name = name, on = not DefaultOff(kind, key, name) })
    end
    return rows
end

local function Saved(kind)
    local saveKey = BuffBot.ListSaveKeys[kind]
    BuffBot.config[saveKey] = BuffBot.config[saveKey] or {}
    return BuffBot.config[saveKey]
end

-- Every entry of a list, in order, as new rows. A saved list loses entries no
-- longer in the defaults and gains new ones at the end, as they start.
function BuffBot.ListRows(kind, key)
    local defaults = BuffBot.DefaultListRows(kind, key)
    local saved = Saved(kind)[key]
    if not saved then return defaults end
    local known, seen, rows = {}, {}, {}
    for _, row in ipairs(defaults) do known[row.name] = true end
    for _, row in ipairs(saved) do
        if known[row.name] and not seen[row.name] then
            seen[row.name] = true
            table.insert(rows, { name = row.name, on = row.on == true })
        end
    end
    for _, row in ipairs(defaults) do
        if not seen[row.name] then table.insert(rows, row) end
    end
    return rows
end

-- The names of a list's entries that are on, in order
function BuffBot.ListOn(kind, key)
    local names = {}
    for _, row in ipairs(BuffBot.ListRows(kind, key)) do
        if row.on then table.insert(names, row.name) end
    end
    return names
end

local function SameRows(a, b)
    if #a ~= #b then return false end
    for i = 1, #a do
        if a[i].name ~= b[i].name or a[i].on ~= b[i].on then return false end
    end
    return true
end

function BuffBot.ListEdited(kind, key)
    return not SameRows(BuffBot.ListRows(kind, key), BuffBot.DefaultListRows(kind, key))
end

-- Saves a list's rows, or forgets it when they match the default, and
-- rebuilds the buff list. Blessings are part of it, so this covers them too.
function BuffBot.SaveList(kind, key, rows)
    if SameRows(rows, BuffBot.DefaultListRows(kind, key)) then
        Saved(kind)[key] = nil
    else
        local copy = {}
        for _, row in ipairs(rows) do table.insert(copy, { name = row.name, on = row.on }) end
        Saved(kind)[key] = copy
    end
    BuffBot.UpdateClassBuffList()
end

function BuffBot.ResetList(kind, key)
    Saved(kind)[key] = nil
    BuffBot.UpdateClassBuffList()
end

function BuffBot.ResetLists(kind)
    BuffBot.config[BuffBot.ListSaveKeys[kind]] = {}
    BuffBot.UpdateClassBuffList()
end

-- Turns one entry on or off, keeping the rest of the list as it is
function BuffBot.SetListEntry(kind, key, name, on)
    local rows = BuffBot.ListRows(kind, key)
    for _, row in ipairs(rows) do
        if row.name == name then row.on = on end
    end
    BuffBot.SaveList(kind, key, rows)
end

-- The checkboxes from before 2.7 that turned a cast-order entry on or off:
-- key, class, entry, and whether true means on
local OLD_TOGGLES = {
    { "IGNORE_THORNS", "DRUID", "Thorns", false },
    { "IGNORE_DAMPEN", "MAGE", "Dampen Magic", false },
    { "IGNORE_INNER_FIRE", "PRIEST", "Inner Fire", false },
    { "IGNORE_LIGHTNING_SHIELD", "SHAMAN", "Lightning Shield", false },
    { "RIGHTEOUS_FURY", "PALADIN", "Righteous Fury", true },
}

-- Moves the old checkboxes' saved values into the cast-order lists, once:
-- the keys are gone afterwards. Runs on ADDON_LOADED with BuffBot.config set.
function BuffBot.MigrateListToggles()
    for _, toggle in ipairs(OLD_TOGGLES) do
        local key, class, name, trueMeansOn = unpack(toggle)
        local value = BuffBot.config[key]
        if value ~= nil then
            local rows = BuffBot.ListRows("cast", class)
            for _, row in ipairs(rows) do
                if row.name == name then row.on = (value == true) == trueMeansOn end
            end
            if SameRows(rows, BuffBot.DefaultListRows("cast", class)) then
                Saved("cast")[class] = nil
            else
                Saved("cast")[class] = rows
            end
            BuffBot.config[key] = nil
        end
    end
end
