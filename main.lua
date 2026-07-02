local Map = require("core.map")
local Events = require("core.events")
local Logger = require("core.logger")
local World = require("core.world")
local Input = require("core.input")
local Registry = require("core.registry")
local Loader = require("core.loader")

local Fonts = require("core.utils.fonts")

local Colors = require("core.render.colors")
local Renderer = require("core.render.renderer")
local UIRenderer = require("core.render.ui_renderer")

Loader.load_core_content()

local MovementSystem = Registry.resolve("systems", "movement")
local InputSystem = Registry.resolve("systems", "input")
local LevelSystem = Registry.resolve("systems", "level")
local HealthSystem = Registry.resolve("systems", "health")
local LoggerSystem = Registry.resolve("systems", "logger")
local InventorySystem = Registry.resolve("systems", "inventory")
local TurnSystem = Registry.resolve("systems", "turn")
local PreviewSystem = Registry.resolve("systems", "preview")
local StatSystem = Registry.resolve("systems", "stats")

local Item = Registry.resolve("components", "item")
local Position = Registry.resolve("components", "position")
local Renderable = Registry.resolve("components", "renderable")
local Stats = Registry.resolve("components", "stats")
local Inventory = Registry.resolve("components", "inventory")
local UIState = Registry.resolve("components", "ui_state")

local Chest = Registry.resolve("prefabs", "chest")

local loaded_mods = {}

-- TODO: level system
-- TODO: save system (serialize game state)
-- TODO: procedural map generation system
-- TODO: combat system and enemies
-- TODO: implement all base stats (for combat and looting)
-- TODO: loot tables in container objects (like chests)

-- TODO: Main/Start menu, start-up glitch effect (see ./ideas.md)
-- TODO: Pause/Exit menu (for when in a game)
--? Probably should also refactor input system to more cleanly work with certain game states

--! [BUG] Fix the issue where mod names are longer than mod list box and don't have auto-wrap (add auto-wrap to title text for mods in mod list)

-- TODO: Find a way to compile to an executable so that you don't need to call `love .` in terminal (ironic, given the visual style of the game)

-- TODO: [DOCS] Ares ECS framework philosophy (Components = Data, Systems = Code, Prefabs = Instances of Components + Systems, Events = activators for Systems)
-- TODO: [DOCS] Getting Started section (setup modding environment, downloading Love2D, etc)
-- TODO: [DOCS] How to build a minimal mod example
-- TODO: [DOCS] How to extend existing content within the Ares ECS framework
-- TODO: [DOCS] How to register new systems, components, and prefabs
-- TODO: [DOCS] How to integrate new UI elements, components, events, systems, and prefabs with existing content
-- TODO: [DOCS] How to subscribe the global logger to custom events
-- TODO: [DOCS] How to render entities/objects/etc. with custom styles and colors
-- TODO: [DOCS] How to add new stats to `core.components.stats`
-- TODO: [DOCS] How to add new rooms to procedural map generation
-- TODO: [DOCS] How to add new TileStyles
-- TODO: [DOCS] How to add new rarities

local logger = Logger.new()
local map = Map.new({
    {
        { type = "W" }, { type = "W" }, { type = "W" }, { type = "W" }, { type = "W" }, { type = "W" }, { type = "W" }
    },
    {
        { type = "W" }, { type = "X" }, { type = "X" }, { type = "X" }, { type = "W" }, { type = "X" }, { type = "W" }
    },
    {
        { type = "W" }, { type = "X" }, { type = "X" }, { type = "X" }, { type = "X" }, { type = "X" }, { type = "W" }
    },
    {
        { type = "W" }, { type = "X" }, { type = "X" }, { type = "X" }, { type = "W" }, { type = "X" }, { type = "W" }
    },
    {
        { type = "W" }, { type = "W" }, { type = "W" }, { type = "W" }, { type = "W" }, { type = "W" }, { type = "W" }
    }
})
local world = World.new()
local player = world:add({
    name = "Player",
    position = Position.new({ x = 2, y = 2 }),
    renderable = Renderable.new({ glyph = "@", fg = Colors.green }),
    stats = Stats.new({ health = 10, movement = 10 }),
    inventory = Inventory.new({}),
    ui = UIState.new({}),

    level = 1
})

map:add_object(Chest.new({x = 4, y = 2}))

world.player = player

Events.on("interact", function(e)

    local target = e.target
    local actor = e.actor

    if not target then
        return
    end

    local dx = math.abs(actor.position.x - target.position.x)
    local dy = math.abs(actor.position.y - target.position.y)

    if dx > 1 or dy > 1 then
        e.cancelled = true
        return
    end

    if target.interactable.interact then
        target.interactable.interact(target, e)
    end

end, 100)


function love.load()
    love._openConsole()
    Fonts.init()

    love.graphics.setDefaultFilter("nearest", "nearest")
    love.window.setTitle("Ares RPG")

    love.keyboard.setKeyRepeat(false)

    TurnSystem.init(Events, world, map, logger)
    InputSystem.init(Events, world, map, logger)
    PreviewSystem.init(Events, world, map, logger)
    MovementSystem.init(Events, world, map, logger)
    HealthSystem.init(Events, world, map, logger)
    LevelSystem.init(Events, world, map, logger)
    LoggerSystem.init(Events, world, map, logger)
    InventorySystem.init(Events, world, map, logger)
    loaded_mods = Loader.load_mod_content(Events, world, map, logger)
    
    -- manually equip player backpack (breaks if you use Events.emit("inventory_equip", {}), since inventory/backpack isn't a regular item)
    player.inventory.equipped = true
    StatSystem.equip(player.stats, player.inventory)
    table.insert(player.stats.equipped_items, player.inventory)

    Events.emit("inventory_add", {
        entity = player,
        item = Item.new({
            name = "Sword",
            description = "A simple bladed weapon",
            rarity = "legendary",
            bonuses = { attack = 5},
        }),
    })
    Events.emit("inventory_add", {
        entity = player,
        item = Item.new({
            name = "Shield",
            description = "A simple shield",
            rarity = "common",
            bonuses = { defense = 5 }
        }),
    })
    Events.emit("inventory_add", {
        entity = player,
        item = Item.new({}), -- add unknown item (is cursed)
    })
    Events.emit("inventory_add", {
        entity = player,
        item = Item.new({
            name = "Fancy Hat",
            description = "You stole some guy's fancy hat.",
            rarity = "epic",
            bonuses = {
                luck = 5,
                defense = 2,
            }
        }),
    })

end

local screen = {} 
local ui = {} 

local function build_ui_context()
    return {
        player = player,
        world = world,
        map = map,
        logger = logger,
        events = Events,
        mods = loaded_mods,
    }
end

function love.draw()
    Renderer.draw(screen) 
    UIRenderer.draw(ui) 
end

function love.update(dt)
    local key = Input.poll() 

    if key then
        Events.emit("input", {
            key = key,
            entity = player
        }) 

    end
    
    Events.emit("tick", { entity = player }) 
    
    screen = Renderer.build(world, map, player.turn_preview, player.position, player.ui.selected_tile) 
    ui = UIRenderer.build(build_ui_context()) 
end

function love.quit()
    print("Game Over!") 
    logger:save("saves/demo.log") 

    Events.emit("shutdown", {}) 
end