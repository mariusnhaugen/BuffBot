-- Classic Era (1.15.x) API surface: the global spell functions that retail
-- removed, and the old Interface Options checkbox template.
local Spells = require("mocks.spells")

return function(state, env)
    -- GetSpellInfo(id) resolves any spell; GetSpellInfo(name) only resolves
    -- spells in the player's spellbook. 7th return is the spell ID.
    function env.GetSpellInfo(spell)
        if spell == nil then return nil end
        local name, id
        if type(spell) == "number" then
            name, id = Spells.nameOf(spell), spell
            if not name then return nil end
        else
            if not state:knows(spell) then return nil end
            name, id = spell, Spells.idOf(spell) or 0
        end
        return name, nil, Spells.iconOf(name), 0, 0, 0, id
    end

    function env.IsUsableSpell(name)
        if not state:knows(name) then return nil, nil end
        return state:isUsable(name), false
    end

    function env.GetSpellTexture(spell)
        local name = type(spell) == "number" and Spells.nameOf(spell) or spell
        if name and state:knows(name) then return Spells.iconOf(name) end
        return nil
    end

    -- Label is exposed as the global <name>Text.
    state.templates.InterfaceOptionsCheckButtonTemplate = function(frame)
        local label = frame:CreateFontString(frame:GetName() and (frame:GetName() .. "Text"))
        frame.Text = label
    end

    state.templates.UICheckButtonTemplate = function(frame)
        frame.text = frame:CreateFontString(frame:GetName() and (frame:GetName() .. "Text"))
    end
end
