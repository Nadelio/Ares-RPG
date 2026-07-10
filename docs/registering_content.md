# Registering New Content

The Registry is the central lookup table for every system, component, and prefab in Ares. Anything that needs to be shared, whether it comes from core or a mod, must register itself here. The rest of the game retrieves it by name using `Registry.resolve`.

```
core.registry
├── systems    - logic modules (have an init function)
├── components - data constructors (have a new function)
└── prefabs    - pre-assembled objects (have a new function)
```

---

## Registry.register

```lua
Registry.register(category, name, value)
```

Adds `value` to `Registry[category]` under `name`, if something is already registered under that name, it errors immediately, duplicate registrations are always a bug.

| Argument   | Type     | Description                                            |
|------------|----------|--------------------------------------------------------|
| `category` | `string` | One of `"systems"`, `"components"`, or `"prefabs"`     |
| `name`     | `string` | The key used to look it up later with `resolve`        |
| `value`    | `table`  | The module table to store                              |

> [!NOTE]
> `Registry.register` is what makes the mod loader aware of your mod, because of this, you don't need to call `init` manually in `mod.lua`, the loader finds and calls it for you automatically.

Ex:
```lua
local Registry = require("core.registry")

local Velocity = {}

function Velocity.new(data)
    return {
        dx = data.dx or 0,
        dy = data.dy or 0,
    }
end

Registry.register("components", "velocity", Velocity)

return Velocity
```

---

## Registry.overwrite

```lua
Registry.overwrite(category, name, value)
```

Unconditionally writes `value` into `Registry[category][name]`, unlike `Registry.register`, it does not error on duplicates, it prints a warning instead.

| Argument   | Type     | Description                                        |
|------------|----------|----------------------------------------------------|
| `category` | `string` | One of `"systems"`, `"components"`, or `"prefabs"` |
| `name`     | `string` | The key to overwrite                               |
| `value`    | `table`  | The replacement module table                       |

> [!WARNING]
> Overwriting a core entry replaces it globally, every other system or mod that resolves that name will now receive your version. Use this only when you intentionally need to replace existing behavior.

Ex:
```lua
local Registry = require("core.registry")

local TeleportMovement = {}

function TeleportMovement.init(Events, world, map, logger)
    Events.on("move", function(e)
        if e.cancelled then return end
        if not e.entity or not e.entity.position then return end

        -- teleport two tiles at a time instead of one
        e.entity.position.x = e.entity.position.x + (e.dx or 0) * 2
        e.entity.position.y = e.entity.position.y + (e.dy or 0) * 2
    end)
end

-- This replaces core's movement system
Registry.overwrite("systems", "movement", TeleportMovement)

return TeleportMovement
```

> [!NOTE]
> `overwrite` always emits a `warn(...)` to the console so you have a record of what was replaced, if you see an unexpected warning at startup, check if one of your mods is overwriting something it shouldn't be.

---

## Registry.resolve

```lua
Registry.resolve(category, name)
```

Looks up and returns the value stored at `Registry[category][name]`, if the entry does not exist, it asserts with an error.

| Argument   | Type     | Description                                        |
|------------|----------|----------------------------------------------------|
| `category` | `string` | One of `"systems"`, `"components"`, or `"prefabs"` |
| `name`     | `string` | The key to retrieve                                |

Returns: the registered table (a system, component constructor, or prefab constructor).

> [!NOTE]
> Only call `resolve` after all modules in the relevant category have been loaded. In practice this means after `Loader.load_core_content()` for core entries, or after `Loader.load_mod_content(...)` for mod entries. Resolving too early will error because the entry hasn't been registered yet.

Ex:
```lua
local Registry = require("core.registry")

local Spawner = {}

function Spawner.init(Events, world, map, logger)
    local Position = Registry.resolve("components", "position")
    local Barrel   = Registry.resolve("prefabs", "barrel")

    Events.on("build_map", function(e)
        for i = 1, 3 do
            map:add_object(Barrel.new({ x = i * 2, y = 3 }))
        end
    end)
end

Registry.register("systems", "barrel_spawner", Spawner)

return Spawner
```

---

## Summary

| Function              | On duplicate | On missing | Use case                                       |
|-----------------------|-------------|------------|------------------------------------------------|
| `Registry.register`   | errors  | | Adding something new                           |
| `Registry.overwrite`  | warns   | | Intentionally replacing existing behavior      |
| `Registry.resolve`    | | errors | Retrieving something you know has been loaded  |
