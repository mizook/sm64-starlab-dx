-- Composition root: require modules while CoopDX is executing this file.
-- Do not require from callbacks: CoopDX resolves paths from the active mod file.
local createState = require("core/state")
local installers = {
    require("catalog"),
    require("core/i18n"),
    require("core/format"),
    require("ui/audio"),
    require("storage/records"),
    require("storage/save_slots"),
    require("practice/attempts"),
    require("practice/checkpoints"),
    require("runs/routes"),
    require("runs/timer"),
    require("runs/intro"),
    require("ui/menu_controller"),
    require("input"),
    require("events"),
    require("commands"),
    require("ui/drawing"),
    require("ui/art"),
    require("ui/run_flow"),
    require("ui/help"),
    require("ui/menu_view"),
    require("ui/run_overlay"),
    require("ui/hud"),
    require("hooks"),
}

local M = {}
local instance

function M.start()
    if instance then
        return instance
    end
    -- Allocate API tables before wiring modules. Cross-module calls happen only
    -- after installation; modules never recursively require one another.
    local app = { version = "0.17.9", state = createState() }
    app.catalog = {}
    app.i18n = {}
    app.format = {}
    app.audio = {}
    app.records = {}
    app.saveSlots = {}
    app.practice = {}
    app.checkpoints = {}
    app.routes = {}
    app.runs = {}
    app.menu = {}
    app.input = {}
    app.events = {}
    app.commands = {}
    app.drawing = {}
    app.art = {}
    app.runFlow = {}
    app.help = {}
    app.menuView = {}
    app.overlay = {}
    app.hud = {}
    for _, install in ipairs(installers) do
        install(app)
    end
    instance = app
    return app
end

return M
