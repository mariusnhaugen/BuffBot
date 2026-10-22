local _, BuffBot = ...

BuffBot.playerclass = (select(2, UnitClass("player")))
--- Helper Functions ---
function BuffBot.IndexOf(value, table)
    for i, v in ipairs(table) do
        if v == value then
            return i
        end
    end
    return nil
end

-- Replaced by the saved config on ADDON_LOADED; empty until then so debug() works
BuffBot.config = {}
function BuffBot.debug(...)
    if BuffBot.config.DEBUG_MODE then
        print(...)
    end
end
