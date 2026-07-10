# Your First Prefab

> [!NOTE]
> This guide assumes you have read the [Ares ECS Framework](./ecs_framework.md) overview and completed [Your First Mod](./first_mod.md). If you haven't, head there first.

By the end of this guide you'll have a working door prefab that blocks movement while closed and lets entities through when open. Interacting with the door toggles its state and updates its visual on the spot. Everything lives in your mod's `prefabs/` folder,  no core files need to be touched.

---

## prefabs/door.lua

Create a new file, `door.lua`, inside your mod's `prefabs/` folder. Copy this template:

```lua
local Registry     = require("core.registry")
local Object       = require("core.components.object")
local Position     = require("core.components.position")
local Renderable   = require("core.components.renderable")
local Interactable = require("core.components.interactable")
local Colors       = require("core.render.colors")

local Door = {}

function Door.new(data)
    -- prefab body here
end

Registry.register("prefabs", "door", Door)

return Door
```

Every prefab follows this same pattern:
- A plain table that acts as the prefab's "namespace".
- A `new(data)` function that builds and returns a fully assembled object from its components.
- A `Registry.register` call so the rest of the game can find it by name.

---

## Building the Base Object

Inside `Door.new`, start with `Object.new`. This sets up the fields every world object needs: a name, a type, a position, a renderable glyph, and the `collides` flag that controls whether entities can walk through it.

```lua
function Door.new(data)
    local obj = Object.new({
        name       = data.name or "Door",
        type       = "door",
        collides   = true,
        position   = Position.new({ x = data.x or 0, y = data.y or 0 }),
        renderable = Renderable.new({ glyph = "+", fg = Colors.yellow }),
    })

    return obj
end
```

A few things to note:
- `collides = true` is the closed state. `MovementRules.can_move` reads this field and will block any entity that tries to step onto the door's tile.
- `glyph = "+"` is the symbol for a closed door.
- `fg = Colors.yellow` gives the door a unique color so it stands out against the floor.

---

## Adding the Interactable Toggle

Right now the door is a purely static object, nothing happens when a player walks up and interacts with it. Add an `Interactable` component with an `interact_func` to give it behaviour when an entity interacts with it.

The `interact_func` receives two arguments: `entity` (the door object itself) and `e` (the event data). Use `e.actor` inside the function if you need to reference the entity that triggered the interaction.

```lua
function Door.new(data)
    local obj = Object.new({
        name       = data.name or "Door",
        type       = "door",
        collides   = true,
        position   = Position.new({ x = data.x or 0, y = data.y or 0 }),
        renderable = Renderable.new({ glyph = "+", fg = Colors.yellow }),
    })

    obj.interactable = Interactable.new({
        interact_func = function(entity, e)
            if entity.collides then
                -- open the door
                entity.collides         = false
                entity.renderable.glyph = "/"
                entity.renderable.fg    = Colors.gray
            else
                -- close the door
                entity.collides         = true
                entity.renderable.glyph = "+"
                entity.renderable.fg    = Colors.yellow
            end
        end,
    })

    return obj
end
```

What this does:
- `entity.collides` tells Ares whether the door is currently closed, so it always knows which way to toggle.
- `entity.collides = false` immediately makes the tile passable, `MovementRules.can_move` will no longer block it on the next movement attempt.
- `entity.renderable.glyph` and `entity.renderable.fg` change what is drawn on the next frame, this way the player knows if the door is open/closed.

> [!NOTE]
> The first argument of `interact_func` is always the object the interactable belongs to, in this case, the door. Use `e.actor` to access the entity that triggered the interaction (almost always the player).

---

## Placing the Door in the World

<!--! CHANGE THIS WHENEVER PROCEDURAL MAP GEN IS FINISHED -->

An object prefab on its own never appears in the game, it needs to be added to the map. Create a small placement system at `systems/door_placer.lua` inside your mod folder:

```lua
local Registry = require("core.registry")

local DoorPlacer = {}

function DoorPlacer.init(Events, world, map, logger)
    local Door = Registry.resolve("prefabs", "door")
    local door = Door.new({ x = 5, y = 3 })
    map:add_object(door)
end

Registry.register("systems", "door_placer", DoorPlacer)

return DoorPlacer
```

- `Registry.resolve("prefabs", "door")` fetches your door prefab by the name you registered. By the time a system's `init` runs, all prefabs in your mod have already been loaded, so this is always safe.
- `map:add_object(door)` registers the door at its tile position so it can be rendered, collided with, and interacted with.
- Change `x` and `y` to the coordinates of a walkable floor tile on the map.

> [!NOTE]
> `Registry.register` raises an error on duplicate names, so if another mod already registers a prefab called `"door"` the game will refuse to start. If you expect conflicts, use a namespaced key like `"my_mod.door"` in both the `register` call and the `resolve` call.

---

## Using the Door

Start Ares and navigate to tile `(5, 3)`. Walk up to the door and interact with it, the glyph should change from `+` to `/` and you should be able to step onto that tile. Interact again to close it.

If nothing seems to happen, double, check:
1. The `x`/`y` coordinates land on a floor tile (`"X"`) and not a wall (`"W"`). An object placed on a wall tile will never be reachable.
2. `Registry.register` is called after both the table and `new` function are defined in `door.lua`.
3. There are no Lua syntax errors, Love2D prints them to the console on startup.

---

For further reading, navigate to the [Events Reference](./events.md) or back to the [Ares ECS Framework](./ecs_framework.md).