-- WoW Forever API surface: the C_Spell namespace that replaced the global
-- spell functions, and the Interface Options checkbox template. Behaviour
-- follows the client probe in TESTING.md.
local Spells = require("mocks.spells")

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

    -- Reads "## Field: value" lines from the addon's TOC
    env.C_AddOns = {
        GetAddOnMetadata = function(addon, field)
            for line in io.lines(addon .. ".toc") do
                local key, value = line:gsub("\r$", ""):match("^##%s*(.-):%s*(.-)%s*$")
                if key == field then return value end
            end
        end,
    }

    -- Label is exposed as the global <name>Text.
    state.templates.InterfaceOptionsCheckButtonTemplate = function(frame)
        local label = frame:CreateFontString(frame:GetName() and (frame:GetName() .. "Text"))
        frame.Text = label
    end

    state.templates.UICheckButtonTemplate = function(frame)
        frame.text = frame:CreateFontString(frame:GetName() and (frame:GetName() .. "Text"))
    end
end
