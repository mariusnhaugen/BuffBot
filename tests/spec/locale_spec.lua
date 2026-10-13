local Addon = require("helpers.load_addon")

-- A client that only understands its own spell names
local function german(name)
    return "DE " .. name
end

describe("non-English client", function()
    it("casts the buff by the client's name, with its icon", function()
        local h = Addon.load({ class = "WARRIOR", known = { "Battle Shout" }, translate = german })
        assert.equal("/cast [target=player]DE Battle Shout", h.button:GetAttribute("macrotext1"))
        assert.equal(h.state:iconOf("Battle Shout"), h.button:GetNormalTexture():GetTexture())
    end)

    it("finds active buffs by the client's name", function()
        local h = Addon.load({ class = "PRIEST", known = { "Power Word: Fortitude", "Inner Fire" }, translate = german })
        assert.same({ "DE Power Word: Fortitude", "DE Inner Fire" }, h:buffUp())
    end)

    it("applies group versions and one-at-a-time buffs", function()
        local h = Addon.load({ class = "DRUID", known = { "Mark of the Wild", "Thorns" }, translate = german })
        h:give("Gift of the Wild")
        assert.equal("DE Thorns", h:shown())

        h = Addon.load({ class = "HUNTER", known = { "Aspect of the Hawk", "Trueshot Aura" }, translate = german })
        h:give("Trueshot Aura")
        h:give("Aspect of the Monkey")
        assert.is_nil(h:shown())
    end)

    it("only counts the player's own Paladin aura", function()
        local h = Addon.load({ class = "PALADIN", known = { "Devotion Aura" }, translate = german })
        h:give("Devotion Aura", { fromPlayer = false })
        assert.equal("DE Devotion Aura", h:shown())
    end)

    it("shows the client's names in the suggestion list", function()
        local h = Addon.load({ class = "PRIEST", known = { "Power Word: Fortitude", "Inner Fire" }, translate = german })
        assert.same({ "DE Power Word: Fortitude", "DE Inner Fire" }, h:suggestions())
    end)

    it("builds the Bloodrage macro and tint with the client's names", function()
        local h = Addon.load({
            class = "WARRIOR",
            known = { "Battle Shout", "Bloodrage" },
            config = { BLOODRAGE = true },
            translate = german,
        })
        h.state.unusable["Battle Shout"] = true
        h:refresh()
        assert.equal("/cast [nocombat] DE Bloodrage\n/cast [target=player]DE Battle Shout",
            h.button:GetAttribute("macrotext1"))

        h:setting("BLOODRAGE", false)
        assert.same({ 0.5, 0.5, 1.0 }, { h.button:GetNormalTexture():GetVertexColor() })
    end)
end)
