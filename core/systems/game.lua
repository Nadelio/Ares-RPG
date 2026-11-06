local Registry = require("core.registry")

local Initializer = {}

function Initializer.init(Events, world, map, logger)

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
    local BrainSystem = Registry.resolve("systems", "brain")
    local CombatSystem = Registry.resolve("systems", "combat")
    local InteractionSystem = Registry.resolve("systems", "interaction")
    local StatusSystem = Registry.resolve("systems", "status")

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

        e.events = Events

        local interactions = InteractionSystem.get_valid_interactions(target, e)

        if #interactions == 0 then
            e.cancelled = true
            return
        end

        if #interactions > 1 and actor.ui then
            actor.ui.interaction_open = true
            actor.ui.interaction_target = target
            actor.ui.interaction_event = e
            actor.ui.interaction_options = interactions
            actor.ui.interaction_selected_index = 1
            e.pending = true
            return
        end

        interactions[1].action(target, e)

    end, 100)

    TurnSystem.init(Events, world, map, logger)
    InputSystem.init(Events, world, map, logger)
    PreviewSystem.init(Events, world, map, logger)
    MovementSystem.init(Events, world, map, logger)
    CombatSystem.init(Events, world, map, logger)
    HealthSystem.init(Events, world, map, logger)
    StatusSystem.init(Events, world, map, logger)
    LevelSystem.init(Events, world, map, logger)
    LoggerSystem.init(Events, world, map, logger)
    InventorySystem.init(Events, world, map, logger)
    MapGenerator.init(Events, world, map, logger)
    LootTableSystem.init(Events, world, map, logger)
    BrainSystem.init(Events, world, map, logger)

    --? manually equip player backpack (breaks if you use Events.emit("inventory_equip", {}), since inventory/backpack isn't a regular item)
    G_player.inventory.equipped = true
    StatSystem.equip(G_player.stats, G_player.inventory)
    table.insert(G_player.stats.equipped_items, G_player.inventory)

    --? need to initialize ClassSystem after equipping the inventory because otherwise you only get a single starter item
    ClassSystem.init(Events, world, map, logger)

    --? Build the map after loading the mods incase a mod changes how map generation works
    Events.emit("build_map", { dimensions = { w = 50, h = 20 } })
end

Registry.register("systems", "game", Initializer)

return Initializer