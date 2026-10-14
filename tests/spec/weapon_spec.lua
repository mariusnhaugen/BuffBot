local Addon = require("helpers.load_addon")

local function shaman(opts)
    opts = opts or {}
    return Addon.load({
        class = "SHAMAN",
        known = opts.known or { "Rockbiter Weapon" },
        config = opts.config,
    })
end

describe("Shaman weapon imbue", function()
    it("recommends Rockbiter on a bare weapon", function()
        local h = shaman()
        assert.equal("Rockbiter Weapon", h:shown())
    end)

    it("is done once the imbue lands, and back when it drops", function()
        local h = shaman()
        h:enchantWeapon(3)
        assert.is_nil(h:shown())
        h:clearWeaponEnchant()
        assert.equal("Rockbiter Weapon", h:shown())
    end)

    it("counts an oil or stone", function()
        local h = shaman()
        h:enchantWeapon(2)
        assert.is_nil(h:shown())
    end)

    it("does not count a permanent enchant", function()
        local h = shaman()
        h:enchantWeapon(1)
        assert.equal("Rockbiter Weapon", h:shown())
    end)

    it("shows again with under 5 minutes left", function()
        local h = shaman()
        h:enchantWeapon(3, 299000)
        assert.equal("Rockbiter Weapon", h:shown())
    end)

    it("is skipped without a main-hand weapon", function()
        local h = shaman()
        h.state.mainHand = nil
        h:clearWeaponEnchant()
        assert.is_nil(h:shown())
    end)

    it("recommends the chosen imbue once learned", function()
        local h = shaman({
            known = { "Rockbiter Weapon", "Windfury Weapon" },
            config = { SHAMAN_IMBUE = "Windfury Weapon" },
        })
        assert.equal("Windfury Weapon", h:shown())
    end)

    it("falls back to Rockbiter until the chosen imbue is learned", function()
        local h = shaman({ config = { SHAMAN_IMBUE = "Windfury Weapon" } })
        assert.equal("Rockbiter Weapon", h:shown())
    end)

    it("comes after Lightning Shield", function()
        local h = shaman({ known = { "Lightning Shield", "Rockbiter Weapon" } })
        assert.same({ "Lightning Shield", "Rockbiter Weapon" }, h:buffUp())
    end)

    it("defaults to Rockbiter", function()
        local h = shaman()
        assert.equal("Rockbiter Weapon", h.ns.config.SHAMAN_IMBUE)
    end)
end)

describe("Shaman imbue setting", function()
    it("offers the four imbues and selects the chosen one", function()
        local h = shaman({ known = { "Rockbiter Weapon", "Flametongue Weapon" } })
        h:slash("")
        assert.equal(4, #h:dropdown("ShamanImbue"))
        assert.equal("Rockbiter Weapon", h:selected("ShamanImbue"))
        h:choose("ShamanImbue", "Flametongue Weapon")
        assert.equal("Flametongue Weapon", h.ns.config.SHAMAN_IMBUE)
        assert.equal("Flametongue Weapon", h:selected("ShamanImbue"))
        assert.equal("Flametongue Weapon", h:shown())
    end)

    it("shows the client's imbue names", function()
        local h = Addon.load({ class = "SHAMAN", known = { "Rockbiter Weapon" }, translate = function(name) return "DE " .. name end })
        h:slash("")
        assert.equal("DE Rockbiter Weapon", h:selected("ShamanImbue"))
    end)
end)
