local Addon = require("helpers.load_addon")

describe("cast button", function()
    it("is a named secure macro button", function()
        local h = Addon.load({ class = "WARRIOR", known = { "Battle Shout" } })
        assert.equal(h.button, h.env.BUFFBOT_MacroButton)
        assert.equal("macro", h.button:GetAttribute("type1"))
    end)

    it("registers the keybind name", function()
        local h = Addon.load()
        assert.equal("BuffBot Cast", h.env["BINDING_NAME_CLICK BUFFBOT_MacroButton:LeftButton"])
    end)

    it("casts the next buff on the player with its icon", function()
        local h = Addon.load({ class = "WARRIOR", known = { "Battle Shout" } })
        assert.equal("/cast [target=player]Battle Shout", h.button:GetAttribute("macrotext1"))
        assert.equal(h.state:iconOf("Battle Shout"), h.button:GetNormalTexture())
        assert.is_true(h.button:IsShown())
    end)

    it("hides when everything is buffed", function()
        local h = Addon.load({ class = "WARRIOR", known = { "Battle Shout" } })
        h:give("Battle Shout")
        assert.is_false(h.button:IsShown())
    end)

    it("reappears when a buff is removed", function()
        local h = Addon.load({ class = "WARRIOR", known = { "Battle Shout" } })
        h:give("Battle Shout")
        h:remove("Battle Shout")
        assert.equal("Battle Shout", h:shown())
    end)

    it("starts at the default position", function()
        local h = Addon.load()
        local point, relativeTo, relativePoint, x, y = h.button:GetPoint()
        assert.same({ "CENTER", h.env.UIParent, "CENTER", 100, 0 }, { point, relativeTo, relativePoint, x, y })
    end)
end)

describe("suggestion list", function()
    local known = { "Power Word: Fortitude", "Shadowform", "Divine Spirit", "Inner Fire" }

    it("lists the current and upcoming buffs", function()
        local h = Addon.load({ class = "PRIEST", known = known })
        assert.same(known, h:suggestions())
    end)

    it("drops buffs as they are applied", function()
        local h = Addon.load({ class = "PRIEST", known = known })
        h:give("Power Word: Fortitude")
        assert.same({ "Shadowform", "Divine Spirit", "Inner Fire" }, h:suggestions())
    end)

    it("leaves out buffs further down the list that are already active", function()
        local h = Addon.load({ class = "PRIEST", known = known })
        h:give("Divine Spirit")
        assert.same({ "Power Word: Fortitude", "Shadowform", "Inner Fire" }, h:suggestions())
    end)

    it("is cleared when SUGGESTION_LIST is turned off", function()
        local h = Addon.load({ class = "PRIEST", known = known })
        h.ns.config.SUGGESTION_LIST = false
        h.ns.UpdateSuggestionList()
        assert.same({}, h:suggestions())
    end)

    it("is not built when SUGGESTION_LIST is off from the start", function()
        local h = Addon.load({ class = "PRIEST", known = known, config = { SUGGESTION_LIST = false } })
        assert.same({}, h:suggestions())
    end)
end)
