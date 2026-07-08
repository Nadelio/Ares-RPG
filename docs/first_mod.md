# Your First Mod

> [!NOTE]
> This guide assumes you have already set up your mod folder and `mod.lua` manifest. If you haven't, head to [Getting Started](./README.md) first.

By the end of this guide you'll have a working mod with a custom system that listens to a game event and reacts to it. The example mod will be a simple step counter, it tracks how many tiles the player has moved and prints a message to the terminal every 10 steps. The full example mod is available in the [mods/ folder](/mods/) if you need it for reference.

---

## systems.step_counter.lua

Create a new file, `step_counter.lua`, inside your mod's `systems/` folder. Copy this template:

```lua
local Registry = require("core.registry")

local StepCounter = {}

function StepCounter.init(Events, world, map, logger)
    -- event receiver functions here
end

Registry.register("systems", "step_counter", StepCounter)

return StepCounter
```

Every system follows this same pattern:
- A plain table that acts as the system's "namespace".
- An `init(Events, world, map, logger)` function where you add receiver functions for events.
- A `Registry.register` call so the Ares ECS Framework can find it.

> [!NOTE]
> The `Registry.register` call is what adds your system to the list of mods for the mod loader, because of this, you don't need to call `StepCounter.init` manually in your `mod.lua`.

## Creating an event receiver function

The `move` event is emitted every time an entity successfully moves one tile. It contains the `entity` that moved, plus `dx` and `dy` for the direction. 
(See: [Events](./events.md))

Add a step counter inside `init`:
```lua
function StepCounter.init(Events, world, map, logger)
    local steps = 0

    Events.on("move", function(e)
        if e.cancelled then return end

        if e.entity ~= world.player then return end

        steps = steps + 1

        if steps % 10 == 0 then
            print("The player has walked " .. steps .. " steps.")
        end
    end)
end
```

A few notes:
- Always protect your `move` receivers with `if e.cancelled then return end`. The `move` events can be cancelled by other systems (walls, enemies blocking the path)
- `world.player` is the reference to the player entity in `main.lua`. You can access any component on it directly
- The optional third argument to `Events.on` is the reciever priority (higher runs first). It defaults to `0`

---

## Using the mod

Start Ares, and walk around, every 10 tiles you walk you should see a line in the terminal like:

```
You've walked 10 steps.
You've walked 20 steps.
```

If you don't see anything, double-check that:
1. Your mod folder name matches the require path in `mod.lua`.
2. `Registry.register` is called after the table and `init` function are defined.
3. There are no Lua syntax errors — Love2D will print them to the console on startup.

---

For further reading, navigate to **[Ares ECS Framework](./ecs_framework.md)** or **[Events Reference](./events.md)**
