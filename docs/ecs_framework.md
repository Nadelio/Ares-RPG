# Ares ECS Framework

Ares is built on an *Entity-Component-System* (ECS for short) architecture.

| Part | Role |
|---|---|
| Components | Pure data - no logic |
| Systems | Pure logic - no state of their own |
| Prefabs | Pre-built groups of components (and sometimes systems) |
| Events | Buttons that activate systems |

Everything is shared through the *Registry*, and every entity lives in the *World*.

---

## Components - Data Only

A component is a table returned by a `new(data)` constructor. It holds data and nothing else. Components never call events, never read from other components, and never contain game logic.

`core.components.position` - where an entity is on the map:
```lua
function Position.new(data)
    return Vec2.new(data.x or 0, data.y or 0)
end
```

`core.components.renderable` - how an entity looks on screen:
```lua
function Renderable.new(data)
    return {
        glyph     = data.glyph or "?",
        fg        = data.fg    or Colors.reset,
        bg        = data.bg    or Colors.black,
        italics   = data.italics   or false,
        bold      = data.bold      or false,
        underline = data.underline or false
    }
end
```

`core.components.stats` - an entity's numeric attributes:
```lua
function Stats.new(data)
    return {
        base = {
            health   = data.health   or 0,
            movement = data.movement or 0,
            attack   = data.attack   or 0,
            defense  = data.defense  or 0,
            luck     = data.luck     or 0,
            capacity = data.capacity or 1,
        },
        bonuses  = {},
        current  = { health = ..., movement = ..., capacity = ... },
        equipped_items = {},
        class = data.class or "None",
        -- ...
    }
end
```

Each component registers itself so the rest of the game can look it up by name:
```lua
Registry.register("components", "position", Position)
```

---

## Systems - Logic Only

A system is a table with an `init(Events, world, map, logger)` function. That function is the system's entire setup, it subscribes to events, and from that point on everything is driven by those subscriptions. Systems do not hold any data for themselves (use components on entities for that).

`core.systems.movement` listens for `move` events and updates the entity's position component:
```lua
function MovementSystem.init(Events, world, map, logger)
    Events.on("move", function(e)
        if e.cancelled then return end
        if not e.entity or not e.entity.position then return end

        local x = e.entity.position.x + (e.dx or 0)
        local y = e.entity.position.y + (e.dy or 0)

        if not MovementRules.can_move(map, x, y) then
            e.cancelled = true
            return
        end

        e.entity.position.x = x
        e.entity.position.y = y
    end, 100)
end
```

`core.systems.health` listens for `attack` and `heal` events and modifies `stats.current.health`:
```lua
function HealthSystem.init(Events, world, map, logger)
    Events.on("attack", function(e)
        local entity = e.target
        entity.stats.current.health = math.max(0, entity.stats.current.health - (e.damage or 0))

        if entity.stats.current.health <= 0 then
            entity.dead = true
            Events.emit("death", { entity = entity, killer = e.attacker })
        end
    end, 100)
end
```

Systems also register themselves:
```lua
Registry.register("systems", "movement", MovementSystem)
```

> [!NOTE]
> The `init` parameters are always `(Events, world, map, logger)` in that order. You can ignore any you don't need, but the parameters must match.

---

## Events - The Buttons

Events are the only way through which systems can talk to each other. One system emits an event and any number of other systems can listen to it.

### Subscribing

```lua
Events.on("move", function(e)
    -- e contains the data passed to Events.emit
end, priority)
```

The optional `priority` number controls execution order, higher runs first. `core` systems typically use `100` for primary systems and `-100` for low-priority observers like `logger`.

### Emitting

```lua
Events.emit("attack", {
    target   = some_entity,
    attacker = player,
    damage   = 5,
})
```

### Cancellation

Every event payload has a `cancelled` field injected automatically. Any listener can set `e.cancelled = true` to stop the chain - all subsequent listeners are skipped. Always check it at the top of listeners that should not run on blocked actions:

```lua
Events.on("move", function(e)
    if e.cancelled then return end
    -- ...
end)
```

### Before/After hooks

`Events.before` and `Events.after` are wrappers that subscribe at very high (`200`) or very low (`-200`) priority, useful for pre-validation or post-processing without touching the `core` systems:

```lua
Events.before("move", function(e)
    -- runs before all normal move listeners
end)

Events.after("move", function(e)
    -- runs after all normal move listeners
end)
```

See the [Events Reference](./events.md) for every built-in event and their parameters.

---

## Prefabs - Pre-made Entities/Objects

A prefab is a factory function that builds a set of components into a usable entity or object. Think of a prefab as a template, `Chest.new({ x = 4, y = 2 })` gives you a fully built chest object without you having to build its components by hand.

**`core.prefabs.chest`** combines `Object`, `Position`, `Renderable`, `Inventory`, and `Interactable`:
```lua
function Chest.new(data)
    local obj = Object.new({
        name     = "Chest",
        type     = "container",
        collides = true,
        position  = Position.new({ x = data.x or 0, y = data.y or 0 }),
        renderable = Renderable.new({ glyph = "C" }),
    })

    obj.inventory    = Inventory.new({ items = data.items or {} })
    obj.interactable = Interactable.new({
        interact_func = function(entity, e)
            -- opens/closes the chest UI on the actor
        end,
    })

    return obj
end
```

Prefabs can also be registered so mods can resolve them by name:
```lua
Registry.register("prefabs", "chest", Chest)
```

---

## The World - Entity List

`world` is the runtime container for every live entity. Adding an entity assigns it a unique numeric `id`:

```lua
local player = world:add({
    name       = "Player",
    position   = Position.new({ x = 2, y = 2 }),
    renderable = Renderable.new({ glyph = "@", fg = Colors.green }),
    stats      = Stats.new({ class = "human" }),
    inventory  = Inventory.new({}),
})
```

You can query the world at any time to find entities that match a condition:

```lua
-- all entities that have a stats component and are alive
local combatants = world:query(function(e)
    return e.stats and e.stats.current.health > 0
end)
```

`world.player` is a direct reference to the player entity, set by `main.lua` after the player is added.

---

## The Registry

The registry is the single place where components, systems, and prefabs are stored and looked up by name. Use `Registry.resolve` to find components, systems, or prefabs that have been registered:

```lua
local Position = Registry.resolve("components", "position")
local MovementSystem = Registry.resolve("systems", "movement")
local Chest = Registry.resolve("prefabs", "chest")
```

`Registry.resolve` raises a fatal error if the requested entry doesn't exist. Registering the same name twice also raises an error, preventing silent overrides. If you want to overwrite `core` systems or components, use `Registry.overwrite`

> [!NOTE]
> Because all core content is loaded by `Loader.load_core_content()` before `love.load()` runs, every core component, system, and prefab is available in the Registry by the time any mod code runs.

---

## Written Example

Here is a full example for a player walking into a wall:

```
InputSystem emits "move" { entity = player, dx = 1, dy = 0 }
    -> MovementSystem reads map tile at (x+1, y), it is a wall
    -> MovementSystem sets e.cancelled = true
    -> LoggerSystem skips (checks e.cancelled)
    -> The player does not move
```

And for a successful move:

```
InputSystem emits "move" { entity = player, dx = 1, dy = 0 }
    -> MovementSystem reads map tile at (x+1, y), it is walkable
    -> MovementSystem moves the player
    -> LoggerSystem records the move to the session log
    -> LevelSystem awards XP for the step
```

---

For further reading, navigate to [Your First Mod](./first_mod.md).