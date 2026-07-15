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
local ClassSystem = Registry.resolve("systems", "class")
local TurnSystem = Registry.resolve("systems", "turn")
local PreviewSystem = Registry.resolve("systems", "preview")
local StatSystem = Registry.resolve("systems", "stats")
local MapGenerator = Registry.resolve("systems", "map_generator")
local LootTableSystem = Registry.resolve("systems", "loot_table")

local Position = Registry.resolve("components", "position")
local Renderable = Registry.resolve("components", "renderable")
local Stats = Registry.resolve("components", "stats")
local Inventory = Registry.resolve("components", "inventory")
local UIState = Registry.resolve("components", "ui_state")

local Chest = Registry.resolve("prefabs", "chest")

local loaded_mods = {}

-- TODO: [WIP] class system
-- TODO: Add weapon/armor advantage/disadvantage
--? [TEST] enemy advantage/disadvantage
--? [TEST] weapons/armor advantage/disadvantage
--? [TEST] unlocked skills, interactions, spells, etc

-- TODO: [WIP] procedural map generation system
-- TODO: object/interactable/entity placer function (placer function should work with anything that has both Renderable and Position components)
-- TODO: larger map support (scrolling map and render only a portion of map)

-- TODO: [BUG] Level up screen always assumes that the player has at least one available skill, even on levels where the current class has no unlockable skills/masteries

-- TODO: combat system and enemies
-- TODO: save system (serialize game state)
-- TODO: implement all base stats (for combat and looting)
-- TODO: loot tables in container-type objects (like chests)

-- TODO: interaction menu (only available if >1 interaction)
-- TODO: spell/skill/action menu (only available if >1 spell/skill/action)

-- TODO: Make player and enemy prefabs
-- TODO: Make item prefabs (for all the starter items and all the items that are generated in loot tables)

-- TODO: Figure out how to fix resolution and minimize/maximize window
-- TODO: Main/Start menu, start-up glitch effect (see ./ideas.md)
-- TODO: Pause/Exit menu (for when in a game)
--? Probably should also refactor core.systems.input to more cleanly work with certain game states

local logger = Logger.new()
local map = Map.new({})
local world = World.new()
local player = world:add({
    name = "Player",
    position = Position.new({ x = 2, y = 2 }),
    renderable = Renderable.new({ glyph = "@", fg = Colors.green }),
    stats = Stats.new({ class = "human" }),
    inventory = Inventory.new({}),
    ui = UIState.new({}),

    level = 1
})

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
    math.randomseed(os.time(), os.time())
    love._openConsole()
    Fonts.init()

    love.graphics.setDefaultFilter("nearest", "nearest")
    love.window.setTitle("Ares RPG")

    love.keyboard.setKeyRepeat(false)

    if not love.filesystem.getInfo("mods", "directory") then
        love.filesystem.createDirectory("mods")
        print("Mods folder created at: " .. love.filesystem.getSaveDirectory() .. "\\mods")
    end

    TurnSystem.init(Events, world, map, logger)
    InputSystem.init(Events, world, map, logger)
    PreviewSystem.init(Events, world, map, logger)
    MovementSystem.init(Events, world, map, logger)
    HealthSystem.init(Events, world, map, logger)
    LevelSystem.init(Events, world, map, logger)
    LoggerSystem.init(Events, world, map, logger)
    InventorySystem.init(Events, world, map, logger)
    MapGenerator.init(Events, world, map, logger)
    LootTableSystem.init(Events, world, map, logger)

    --? manually equip player backpack (breaks if you use Events.emit("inventory_equip", {}), since inventory/backpack isn't a regular item)
    player.inventory.equipped = true
    StatSystem.equip(player.stats, player.inventory)
    table.insert(player.stats.equipped_items, player.inventory)

    --? need to initialize ClassSystem after equipping the inventory because otherwise you only get a single starter item
    ClassSystem.init(Events, world, map, logger)

    loaded_mods = Loader.load_mod_content(Events, world, map, logger)
    print("Loaded " .. #loaded_mods .. " mods.")

    --? Build the map after loading the mods incase a mod changes how map generation works
    Events.emit("build_map", { dimensions = { w = 50, h = 20 } })
    
    map:add_object(Chest.new({
        x = player.position.x + 1,
        y = player.position.y
    })) -- place a chest to the right of the player
    Events.emit("generate_loot_table", { -- fill chest with items
        container = map:get_object(player.position.x + 1, player.position.y),
    })

    map:add_object(Chest.new({
        x = player.position.x,
        y = player.position.y + 1
    })) -- place a chest below the player
    Events.emit("generate_loot_table", {
        container = map:get_object(player.position.x, player.position.y + 1),
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