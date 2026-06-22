local Map = require("core.map") 
local Events = require("core.events") 
local Logger = require("core.logger") 
local World = require("core.world") 
local Input = require("core.input") 
local Fonts = require("core.utils.fonts") 
local Item = require("core.components.item") 

local Colors = require("core.render.colors")
local Renderer = require("core.render.renderer") 
local UIRenderer = require("core.render.ui_renderer") 

local MovementSystem = require("core.systems.movement") 
local InputSystem = require("core.systems.input") 
local LevelSystem = require("core.systems.level") 
local HealthSystem = require("core.systems.health") 
local LoggerSystem = require("core.systems.logger") 
local InventorySystem = require("core.systems.inventory") 
local TurnSystem = require("core.systems.turn") 
local PreviewSystem = require("core.systems.preview") 

local Position = require("core.components.position") 
local Renderable = require("core.components.renderable") 
local Stats = require("core.components.stats") 
local Inventory = require("core.components.inventory") 
local UIState = require("core.components.ui_state") 

local Chest = require("content.chest") 

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
    position = Position.new(2, 2),
    renderable = Renderable.new({ glyph = "@", fg = Colors.green }),
    stats = Stats.new({ health = 10, movement = 10 }),
    inventory = Inventory.new({}),
    ui = UIState.new(),

    level = 1
}) 

map:add_object(Chest.new(4, 2)) 

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

    TurnSystem.init(world, Events) 
    InputSystem.init(world, map, Events) 
    PreviewSystem.init(world, map, Events) 
    MovementSystem.init(world, map, Events) 
    HealthSystem.init(Events) 
    LevelSystem.init(Events) 
    LoggerSystem.init(Events, logger) 
    InventorySystem.init(Events) 

    Events.emit("inventory_add", {
        entity = player,
        item = Item.new({
            name = "Sword",
            description = "A simple bladed weapon",
            attack = 5,
            rarity = "legendary"
        }),
    }) 
    Events.emit("inventory_add", {
        entity = player,
        item = Item.new({
            name = "Shield",
            description = "A simple shield",
            defense = 5,
            rarity = "common"
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
            luck = 5,
            defense = 2,
            rarity = "epic"
        }),
    }) 
end

local screen = {} 
local ui = {} 

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
    ui = UIRenderer.build(player) 
end

function love.quit()
    print("Game Over!") 
    logger:save("saves/demo.log") 

    Events.emit("shutdown", {}) 
end