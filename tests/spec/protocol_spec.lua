local Addon = require("helpers.load_addon")

-- Scripted peers: one client, with other BuffBot Paladins' messages injected.
-- The player is "Tester", which sorts after "Ann Peer" and "Bob Peer" and
-- before "Zed Peer".
describe("coordination messages", function()
    local function paladin(opts)
        opts = opts or {}
        opts.class = opts.class or "PALADIN"
        opts.known = opts.known or { "Blessing of Might", "Blessing of Wisdom", "Blessing of Kings", "Devotion Aura" }
        local h = Addon.load(opts)
        h.state.random = function() return 0.5 end -- answers go out after 1 second
        return h
    end

    local function raid(h, names)
        local members = {}
        for _, name in ipairs(names or {}) do table.insert(members, { class = "PALADIN", name = name }) end
        h:joinRaid(members)
    end

    describe("joining a raid", function()
        it("sends a hello", function()
            local h = paladin()
            raid(h, { "Ann Peer" })
            assert.same({ "BB?:v1:-" }, h:sent())
        end)

        it("sends nothing for other classes", function()
            local h = paladin({ class = "PRIEST", known = { "Power Word: Fortitude" } })
            raid(h, { "Ann Peer" })
            assert.same({}, h:sent())
        end)

        it("sends nothing with group buffing turned off", function()
            local h = paladin({ config = { GROUP_BUFFING = false } })
            raid(h, { "Ann Peer" })
            h:receive("Ann Peer", "BB?:v1:-")
            h.state:advance(5)
            assert.same({}, h:sent())
        end)

        it("sends nothing in a battleground", function()
            local h = paladin()
            h.state.instanceType = "pvp"
            raid(h, { "Ann Peer" })
            assert.same({}, h:sent())
        end)

        it("sends nothing in a party", function()
            local h = paladin()
            h:joinParty({ { class = "PALADIN", name = "Ann Peer" } })
            assert.same({}, h:sent())
        end)

        it("takes a slot once the answers are in", function()
            local h = paladin()
            raid(h, { "Ann Peer", "Bob Peer" })
            h:receive("Ann Peer", "BB:v1:K")
            h:receive("Bob Peer", "BB:v1:MW")
            assert.equal("-", h.ns.MySlot())
            h:settle()
            assert.equal("M", h.ns.MySlot())
            assert.same({ "BB?:v1:-", "BB:v1:M" }, h:sent())
            assert.is_true(h.ns.Coordinating())
        end)

        it("stays without a slot when nobody answers", function()
            local h = paladin()
            raid(h, {})
            h:settle()
            assert.equal("-", h.ns.MySlot())
            assert.is_false(h.ns.Coordinating())
            assert.same({ "BB?:v1:-" }, h:sent())
        end)
    end)

    describe("answering", function()
        local function settled(names)
            local h = paladin()
            raid(h, names)
            h:settle()
            h.state.sent = {}
            return h
        end

        it("answers a hello once, after a random delay", function()
            local h = settled({ "Zed Peer" })
            h:receive("Zed Peer", "BB?:v1:-")
            -- Tester sorts first, so takes Kings and says so straight away
            assert.same({ "BB:v1:K" }, h:sent())
            h.state:advance(2)
            assert.same({ "BB:v1:K" }, h:sent())
        end)

        it("answers with its state when the hello changes nothing", function()
            local h = settled({ "Zed Peer", "Ann Peer" })
            h:receive("Ann Peer", "BB:v1:K")
            h:receive("Zed Peer", "BB?:v1:-")
            h.state:advance(2)
            h.state.sent = {}
            h:receive("Zed Peer", "BB?:v1:-")
            assert.same({}, h:sent())
            h.state:advance(1)
            assert.same({ "BB:v1:W" }, h:sent())
        end)

        it("splits Might/Wisdom when a third Paladin says hello", function()
            local h = settled({ "Ann Peer", "Zed Peer" })
            h:receive("Ann Peer", "BB:v1:K")
            assert.equal("MW", h.ns.MySlot())
            h.state.sent = {}
            h:receive("Zed Peer", "BB?:v1:-")
            assert.equal("W", h.ns.MySlot())
            h.state:advance(2)
            assert.same({ "BB:v1:W" }, h:sent())
        end)

        it("keeps its slot against a stale hello", function()
            local h = settled({ "Ann Peer", "Bob Peer" })
            h:receive("Ann Peer", "BB:v1:K")
            h:receive("Bob Peer", "BB:v1:W")
            assert.equal("M", h.ns.MySlot())
            h:receive("Ann Peer", "BB?:v1:M")
            assert.equal("M", h.ns.MySlot())
        end)

        it("ignores messages from other versions and from outside the raid", function()
            local h = settled({ "Ann Peer" })
            h:receive("Ann Peer", "BB:v2:K")
            h:receive("Someone Else", "BB:v1:K")
            h:receive("Ann Peer", "BB:v1:Q")
            assert.equal("-", h.ns.MySlot())
            assert.is_false(h.ns.Coordinating())
            assert.same({}, h:sent())
        end)

        it("treats a Paladin who switches to another version as gone", function()
            local h = settled({ "Ann Peer", "Bob Peer" })
            h:receive("Ann Peer", "BB:v1:K")
            h:receive("Bob Peer", "BB:v1:W")
            assert.equal("M", h.ns.MySlot())
            h:receive("Bob Peer", "BB:v2:W")
            assert.equal("MW", h.ns.MySlot())
        end)
    end)

    describe("Paladins leaving", function()
        local function three()
            local h = paladin()
            raid(h, { "Ann Peer", "Bob Peer" })
            h:receive("Ann Peer", "BB:v1:K")
            h:receive("Bob Peer", "BB:v1:W")
            h:settle()
            h.state.sent = {}
            return h
        end

        it("frees the slot of one who goes offline", function()
            local h = three()
            assert.equal("M", h.ns.MySlot())
            h.state.members.raid3.offline = true
            h:fire("UNIT_CONNECTION", "raid3")
            assert.equal("MW", h.ns.MySlot())
            assert.same({ "BB:v1:MW" }, h:sent())
        end)

        it("frees the slot of one who leaves the raid", function()
            local h = three()
            h:joinRaid({ { class = "PALADIN", name = "Bob Peer" } })
            assert.equal("K", h.ns.MySlot())
        end)

        it("keeps the slot of one who dies", function()
            local h = three()
            h.state.members.raid3.dead = true
            h:fire("UNIT_CONNECTION", "raid3")
            assert.equal("M", h.ns.MySlot())
        end)

        it("drops coordination on leaving the raid", function()
            local h = three()
            h:leaveGroup()
            assert.equal("-", h.ns.MySlot())
            assert.is_false(h.ns.Coordinating())
        end)

        it("stops taking part when group buffing is turned off", function()
            local h = three()
            h:setting("GROUP_BUFFING", false)
            assert.is_false(h.ns.Coordinating())
            h:receive("Ann Peer", "BB?:v1:K")
            h.state:advance(2)
            assert.same({}, h:sent())
        end)
    end)

    describe("sending", function()
        it("sends a refused message again after combat", function()
            local h = paladin()
            raid(h, { "Ann Peer", "Bob Peer" })
            h:receive("Ann Peer", "BB:v1:K")
            h:receive("Bob Peer", "BB:v1:MW")
            h:enterCombat()
            h.state.sendResult = 11
            h:settle()
            assert.same({ "BB?:v1:-" }, h:sent())
            h.state.sendResult = nil
            h:leaveCombat()
            assert.same({ "BB?:v1:-", "BB:v1:M" }, h:sent())
        end)

        it("prints what it sends in debug mode", function()
            local h = paladin({ config = { DEBUG_MODE = true } })
            raid(h, {})
            assert.is_true(h:printed("BuffBot sent on RAID: BB?:v1:-"))
        end)
    end)

    describe("blessings", function()
        it("wait for a hello's answers, but auras don't", function()
            local h = paladin()
            raid(h, { "Ann Peer" })
            assert.equal("Devotion Aura", h:shown())
            h:give("Devotion Aura")
            assert.is_nil(h:shown())
            h:settle()
            assert.equal("Blessing of Might", h:shown())
        end)

        it("wait while another Paladin's hello is answered", function()
            local h = paladin()
            h:give("Devotion Aura")
            raid(h, {})
            h:settle()
            assert.equal("Blessing of Might", h:shown())
            h.state.members.raid2 = { class = "PALADIN", name = "Zed Peer", subgroup = 1, auras = {} }
            h:receive("Zed Peer", "BB?:v1:-")
            assert.is_nil(h:shown())
            h:settle()
            assert.equal("Blessing of Might", h:shown())
        end)
    end)
end)
