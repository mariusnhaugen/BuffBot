local _, BuffBot = ...

BuffBot.playername = GetUnitName("player")
BuffBot.playerlevel = UnitLevel("player")
BuffBot.playerclass = (select(2, UnitClass("player")))
--- Helper Functions ---
function BuffBot:StringIsPartOfTable(string, table) 
    local StringMatchFound = false
    -- print("StringIsPartOfTable: ", string)
    for _, value in pairs(table) do
        if (string == value) then 
            StringMatchFound = true
            break
         end
    end
    return StringMatchFound;
end
