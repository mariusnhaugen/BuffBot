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

        GetSpellTexture = function(spell)
            local name = type(spell) == "number" and Spells.nameOf(spell) or state:englishName(spell)
            if name and state:knows(name) then return Spells.iconOf(name) end
            return nil
        end,
    }

    env.C_Item = {
        -- Two entries, like the probe. In game the enchant can be in either
        -- (Rockbiter was second, a weightstone first); here it's second.
        GetWeaponEnchantInfo = function(weaponSlot)
            local empty = { hasEnchant = false, enchantType = 0, timeLeft = 0, charges = 0, enchantID = 0, enchantIconID = 0 }
            local enchant = state.weaponEnchants[weaponSlot]
            if not enchant then return { empty, empty } end
            return { empty, {
                hasEnchant = true,
                enchantType = enchant.type,
                timeLeft = enchant.timeLeft,
                charges = enchant.charges or 0,
                enchantID = 29,
                enchantIconID = 136086,
            } }
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

    env.C_Timer = {
        After = function(seconds, callback)
            table.insert(state.timers, { at = state.time + seconds, callback = callback })
        end,
    }

    function env.GetInventoryItemID(unit, slot)
        if unit ~= "player" then return nil end
        if slot == 16 then return state.mainHand end
        if slot == 17 then return state.offHand end
        return nil
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
