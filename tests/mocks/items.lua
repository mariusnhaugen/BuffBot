-- Item name <-> ID table for the fake game: the poisons, every rank, and
-- the group buff reagents.
local byName = {
    ["Instant Poison"] = 6947,
    ["Instant Poison II"] = 6949,
    ["Instant Poison III"] = 6950,
    ["Instant Poison IV"] = 8926,
    ["Instant Poison V"] = 8927,
    ["Instant Poison VI"] = 8928,
    ["Deadly Poison"] = 2892,
    ["Deadly Poison II"] = 2893,
    ["Deadly Poison III"] = 8984,
    ["Deadly Poison IV"] = 8985,
    ["Deadly Poison V"] = 20844,
    ["Crippling Poison"] = 3775,
    ["Crippling Poison II"] = 3776,
    ["Mind-numbing Poison"] = 5237,
    ["Mind-numbing Poison II"] = 6951,
    ["Mind-numbing Poison III"] = 9186,
    ["Wound Poison"] = 10918,
    ["Wound Poison II"] = 10920,
    ["Wound Poison III"] = 10921,
    ["Wound Poison IV"] = 10922,
    -- Reagents for the group buffs
    ["Wild Berries"] = 17021,
    ["Thornroot"] = 17026,
    ["Arcane Powder"] = 17020,
    ["Holy Candle"] = 17028,
    ["Sacred Candle"] = 17029,
}

local byID = {}
for name, id in pairs(byName) do
    byID[id] = name
end

local Items = {}

function Items.idOf(name)
    return byName[name]
end

function Items.nameOf(id)
    return byID[id]
end

function Items.iconOf(name)
    return "Interface\\Icons\\" .. name
end

return Items
