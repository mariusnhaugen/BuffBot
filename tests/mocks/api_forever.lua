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
                return name and info(name, spell)
            end
            if not state:knows(spell) then return nil end
            return info(spell, Spells.idOf(spell) or 0)
        end,

        IsSpellUsable = function(name)
            if not state:knows(name) then return false, false end
            return state:isUsable(name), false
        end,

        GetSpellTexture = function(spell)
            local name = type(spell) == "number" and Spells.nameOf(spell) or spell
            if name and state:knows(name) then return Spells.iconOf(name) end
            return nil
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
