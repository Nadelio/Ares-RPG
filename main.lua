local Registry = require("core.registry")
local Events = require("core.events")
local Input = require("core.input")
local Loader = require("core.loader")
local Map = require("core.map")
local Logger = require("core.logger")
local World = require("core.world")
local Colors = require("core.render.colors")

local Fonts = require("core.utils.fonts")

local Renderer = require("core.render.renderer")
local UIRenderer = require("core.render.ui_renderer")

local loaded_mods = {}

-- TODO: combat system enhancements and enemies
    --? Death state for both the player and npcs/enemies
        --? Can't move and gain a new interaction to view their inventory like a chest
    --? Add weapon/armor advantage/disadvantage to combat resolution
    --? Add interaction and combat radius highlights
    --? Add concrete status effects and items that apply them
-- TODO: [WIP] class system
    -- TODO: Add weapon/armor advantage/disadvantage
    --? [TEST] enemy advantage/disadvantage
    --? [TEST] weapons/armor advantage/disadvantage
    --? [TEST] unlocked skills, interactions, spells, etc
-- TODO: implement all base stats (for combat and looting)
    --? Need to modify loot tables to bias towards higher rarity items
    --? Need to mess with the rarity colors stuff and make it part of the Item component as an enum

-- TODO: save system (serialize game state)
-- TODO: Make player and enemy prefabs

-- TODO: Rework UI and input systems so they don't need hard-coded handling for every new UI widget
--? Probably should also refactor core.systems.input to more cleanly work with all game states under the hood

-- TODO: spell/skill/action menu (only available if >1 spell/skill/action)

-- TODO: [BUG] On Linux and MacOS releases, window scale is backwards, solution: "render to an offscreen canvas"
    --? love.graphics.newCanvas(), love.graphics.setCanvas()
    --? add render scale setting 
-- TODO: larger map support (scrolling map and render only a portion of map)

-- TODO: Main/Start menu, start-up glitch effect (see ./ideas.md)
-- TODO: Pause/Exit menu (for when in a game)

G_logger = {}
G_map = {}
G_world = {}
G_player = {}
G_settings = {}

function love.load(arg)
    math.randomseed(os.time(), os.time())

    local needhdpi = love.system.getOS() == "OS X"
    love.window.setMode(800, 600, { resizable = true, minwidth = 800, minheight = 600, highdpi = needhdpi })

    Fonts.init()

    love.graphics.setDefaultFilter("nearest", "nearest")
    love.window.setTitle("Ares RPG")

    love.keyboard.setKeyRepeat(false)

    Loader.load_core_content()

    if not love.filesystem.getInfo("mods", "directory") then
        love.filesystem.createDirectory("mods")
        print("Mods folder created at: " .. love.filesystem.getSaveDirectory() .. "\\mods")
    end

    --? Need to build the globals before loading mod content in case a mod patches one of them
    local Position = Registry.resolve("components", "position")
    local Renderable = Registry.resolve("components", "renderable")
    local Stats = Registry.resolve("components", "stats")
    local Inventory = Registry.resolve("components", "inventory")
    local UIState = Registry.resolve("components", "ui_state")
    local Settings = Registry.resolve("components", "settings")

    G_logger = Logger.new()
    G_settings = Settings.new({
        sprite_rendering = false --? default value for setting
    })
    G_map = Map.new({})
    G_world = World.new()
    G_player = G_world:add({
        name = "Player",
        position = Position.new({ x = 2, y = 2 }),
        renderable = Renderable.new({
            glyph = "@",
            fg = Colors.green,
            sprite = {
                x = 1, y = 0, resolution = 16
            }
        }),
        stats = Stats.new({ class = "human" }),
        inventory = Inventory.new({}),
        ui = UIState.new({}),

        level = 1
    })

    G_world.player = G_player

    loaded_mods = Loader.load_mod_content(Events, G_world, G_map, G_logger)
    print("Loaded " .. #loaded_mods .. " mods.")

    --? Move Ares initialization to a system in case someone wants to override it in a mod
    local Game = Registry.resolve("systems", "game")
    Game.init(Events, G_world, G_map, G_logger)
end

local screen = {}
local ui = {}

local function build_ui_context()
    return {
        player = G_player,
        world = G_world,
        map = G_map,
        logger = G_logger,
        events = Events,
        mods = loaded_mods,
    }
end

function love.draw()
    Renderer.draw(screen, G_settings)
    UIRenderer.draw(ui, G_settings)
end

function love.update(dt)
    local event = Input.poll()

    if event then
        Events.emit("input", {
            key = event.key,
            actions = event.actions,
            entity = G_player
        })
    end

    Events.emit("tick", { entity = G_player })

    screen = Renderer.build(G_world, G_map, G_player.turn_preview, G_player.position, G_player.ui.selected_tile)
    ui = UIRenderer.build(build_ui_context(), G_settings)

    Input.end_frame()
end

function love.quit()
    print("Game Over!") 
    G_logger:save("saves/demo.log")

    Events.emit("shutdown", {})
end