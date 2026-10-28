-- WoW Forever API surface: the C_Spell namespace that replaced the global
-- spell functions, and the Interface Options checkbox template. Behaviour
-- follows the client probe results in PROBE_RESULTS.md.
local Spells = require("mocks.spells")
local Items = require("mocks.items")

return function(state, env)
    local function info(name, id)
        return { name = name, iconID = Spells.iconOf(name), spellID = id, castTime = 0, minRange = 0, maxRange = 0 }
    end

    env.C_Spell = {
        -- By ID resolves any spell; by name only resolves spells in the
        -- player's spellbook.
        GetSpellInfo = function(spell)
            if spell == nil then return nil end
            if type(spell) == "number" then
                local name = Spells.nameOf(spell)
                return name and info(state:localName(name), spell)
            end
            local english = state:englishName(spell)
            if not english or not state:knows(english) then return nil end
            return info(spell, Spells.idOf(english) or 0)
        end,

        IsSpellUsable = function(name)
            local english = state:englishName(name)
            if not english or not state:knows(english) then return false, false end
            -- unusable spells are out of mana or rage
            return state:isUsable(english), state.unusable[english] == true
        end,

        -- Plain true/false, as in the probe. Members are in range unless
        -- set otherwise.
        IsSpellInRange = function(_, unit)
            local member = state.members[unit]
            if member then return member.inRange ~= false end
            return state:resolve(unit) == "player"
        end,

        -- Only the global cooldown is modelled
        GetSpellCooldown = function()
            if state.gcdUntil > state.time then
                return { startTime = state.gcdUntil - 1.5, duration = 1.5, isEnabled = true, modRate = 1 }
            end
            return { startTime = 0, duration = 0, isEnabled = true, modRate = 1 }
        end,

        GetSpellTexture = function(spell)
            local name = type(spell) == "number" and Spells.nameOf(spell) or state:englishName(spell)
            if name and state:knows(name) then return Spells.iconOf(name) end
            return nil
        end,
    }

    -- Tracking that replaces any other: every tracker but Find Treasure
    local function exclusiveTracker(name)
        return name ~= "Find Treasure" and (name:find("^Find ") or name:find("^Track ")) ~= nil
    end

    -- Casts tracking without a key press, as in the probe. Fails during the
    -- global cooldown or another cast; otherwise the aura goes on and the
    -- global cooldown starts.
    function env.CastSpellByID(id)
        local name = Spells.nameOf(id)
        table.insert(state.casts, name)
        if state.gcdUntil > state.time or state.casting or not state:knows(name) then return end
        if exclusiveTracker(name) then
            for other in pairs(state.auras) do
                if exclusiveTracker(other) then state.auras[other] = nil end
            end
        end
        state:giveAura(name, { duration = 0 })
        state.gcdUntil = state.time + 1.5
    end

    env.C_Item = {
        -- Two entries, like the probe. In game the enchant can be in either
        -- (Rockbiter was second, a weightstone first); here it's second unless
        -- state.enchantEntry says 1.
        GetWeaponEnchantInfo = function(weaponSlot)
            local empty = { hasEnchant = false, enchantType = 0, timeLeft = 0, charges = 0, enchantID = 0, enchantIconID = 0 }
            local enchant = state.weaponEnchants[weaponSlot]
            if not enchant then return { empty, empty } end
            local entries = { empty, empty }
            entries[state.enchantEntry or 2] = {
                hasEnchant = true,
                enchantType = enchant.type,
                timeLeft = enchant.timeLeft,
                charges = enchant.charges or 0,
                enchantID = 29,
                enchantIconID = 136086,
            }
            return entries
        end,

        GetItemCount = function(itemID)
            return state.bags[itemID] or 0
        end,

        GetItemNameByID = function(itemID)
            local name = Items.nameOf(itemID)
            return name and state:localName(name)
        end,

        GetItemIconByID = function(itemID)
            local name = Items.nameOf(itemID)
            return name and Items.iconOf(name)
        end,
    }

    -- state.SECRET stands in for a secret value
    function env.issecretvalue(value)
        return value == state.SECRET
    end

    env.C_Timer = {
        After = function(seconds, callback)
            table.insert(state.timers, { at = state.time + seconds, callback = callback })
        end,
    }

    -- Add-on messages. Each prefix has 10 sends, refilling at 1 a second;
    -- past that a send fails with 3 (AddonMessageThrottle) and is dropped.
    -- The result comes last, as from the deprecation wrapper, so the add-on
    -- has to read it with select(-1, ...). state.sendResult forces a result,
    -- e.g. 11 for AddOnMessageLockdown.
    local allowance = {}
    env.C_ChatInfo = {
        RegisterAddonMessagePrefix = function(prefix)
            state.prefixes[prefix] = true
            return nil, 0
        end,
        SendAddonMessage = function(prefix, text, chatType)
            if not state.prefixes[prefix] then return nil, 1 end
            if state.sendResult then return nil, state.sendResult end
            local a = allowance[prefix] or { left = 10, at = state.time }
            a.left = math.min(10, a.left + (state.time - a.at))
            a.at = state.time
            allowance[prefix] = a
            if a.left < 1 then return nil, 3 end
            a.left = a.left - 1
            table.insert(state.sent, { prefix = prefix, text = text, chatType = chatType })
            return nil, 0
        end,
    }

    -- math.random returns state.random(...) when a spec sets it
    env.math = setmetatable({
        random = function(...)
            if state.random then return state.random(...) end
            return math.random(...)
        end,
    }, { __index = math })

    function env.GetInventoryItemID(unit, slot)
        if unit ~= "player" then return nil end
        if slot == 16 then return state.mainHand end
        if slot == 17 then return state.offHand end
        return nil
    end

    function env.GetLocale() return state.locale end

    env.LOCALIZED_CLASS_NAMES_MALE = {}
    for _, class in ipairs({ "WARRIOR", "ROGUE", "HUNTER", "MAGE", "WARLOCK", "PRIEST", "DRUID", "SHAMAN", "PALADIN" }) do
        env.LOCALIZED_CLASS_NAMES_MALE[class] = "Class " .. class
    end

    -- Reads "## Field: value" lines from the addon's TOC
    env.C_AddOns = {
        GetAddOnMetadata = function(addon, field)
            for line in io.lines(addon .. ".toc") do
                local key, value = line:gsub("\r$", ""):match("^##%s*(.-):%s*(.-)%s*$")
                if key == field then return value end
            end
        end,
    }

    state.templates.UICheckButtonTemplate = function(frame)
        frame.text = frame:CreateFontString(frame:GetName() and (frame:GetName() .. "Text"))
    end
end
