# Using the Logger

> [!NOTE]
> This guide assumes you have read [Your First Mod](./first_mod.md) and understand how systems and event receivers work. If you haven't, head there first.

By the end of this guide you'll know how to record game events using the global logger, add new log entries for your own custom events, and create a separate logger instance when your mod needs its own isolated log file.

---

## The Global Logger

The global `logger` instance is created in `main.lua` and passed as the fourth argument to every system's `init` function:

```lua
function MySystem.init(Events, world, map, logger)
    -- logger is available here
end
```

It is the same instance used by all core systems, and its contents are written to `saves/core.log` when the game shuts down. Because it is shared, any entries your mod adds will appear alongside core entries in the same log file, sorted by turn order.

---

## Subscribing the Logger to Events

To record an event, call `logger:add(eventType, format_fn, data)` inside an event receiver. The first argument is a string that names the entry type, the second is an optional format function (pass `nil` to use built-in formatting for core event types), and the third is a table of data to store alongside the entry.

Example log:
```lua
local Registry = require("core.registry")

local MySystem = {}

function MySystem.init(Events, world, map, logger)
    Events.on("level_up", function(e)
        logger:add("level_up", nil, {
            entity    = e.entity.name,
            new_level = e.new_level,
        })
    end, -100)
end

Registry.register("systems", "my_system", MySystem)

return MySystem
```

A few things to note:
- A priority of `-100` means this receiver runs after most others. This is a good default for logging so you record the final, settled state of the event rather than an in-progress one.
- The `data` table keys are up to you. Only pass what is meaningful to read back later.
- `logger:add` returns the entry it created if you need to inspect or store it.

---

## Adding New Log Types

You are not limited to the built-in event type strings. Pass any string as the first argument to `logger:add` and provide a format function as the second argument to control how the entry appears in the saved log.

The format function receives the full log entry and must return a string. The entry has three fields available to it:
- `turn` - the action number at the time of logging
- `type` - the event type string you passed
- `data` - the table you passed as the third argument

This example is for a trap system. It subscribes to a custom `trap_triggered` event and logs using a custom format:
```lua
local Registry = require("core.registry")

local TrapSystem = {}

function TrapSystem.init(Events, world, map, logger)
    Events.on("trap_triggered", function(e)
        logger:add("trap_triggered", function(entry)
            return string.format(
                "[Action %d] TRAP %s caught %s (%d dmg)",
                entry.turn,
                entry.data.trap,
                entry.data.victim,
                entry.data.damage
            )
        end, {
            victim = e.entity.name,
            trap   = e.trap.name,
            damage = e.damage or 0,
        })
    end, -100)
end

Registry.register("systems", "trap_system", TrapSystem)

return TrapSystem
```

When the game saves, entries will appear in `saves/demo.log` like:

```
[Action 7] TRAP Spike Pit caught Player (5 dmg)
```

If you omit the format function (`nil`), unrecognised event types fall back to a generic line:

```
[Action 7] trap_triggered
```

---

## Creating a Custom Logger

If you need your own formatted log file separate from the core save log, require `core.logger` directly and create a new instance with `Logger.new()`. You need to remember to call `:save(path)` when you want to write it to disk.

```lua
local Registry = require("core.registry")
local Logger   = require("core.logger")

local TrapSystem = {}
local trap_log   = Logger.new()

function TrapSystem.init(Events, world, map, logger)
    Events.on("trap_triggered", function(e)
        trap_log:add("trap_triggered", function(entry)
            return string.format(
                "[Action %d] TRAP %s caught %s (%d dmg)",
                entry.turn,
                entry.data.trap,
                entry.data.victim,
                entry.data.damage
            )
        end, {
            victim = e.entity.name,
            trap   = e.trap.name,
            damage = e.damage or 0,
        })
    end, -100)

    Events.on("shutdown", function()
        trap_log:save("saves/traps.log")
    end)
end

Registry.register("systems", "trap_system", TrapSystem)

return TrapSystem
```

A few notes:
- `trap_log` is declared outside `init` so it persists for the lifetime of the system.
- Saving on the `shutdown` event keeps the call out of your `init` and guarantees it runs at the right time.
- The saved file will be placed relative to the Love2D save directory, the same location as `saves/demo.log`.
- The custom logger supports format functions the same way as the global logger, pass one as the second argument to `trap_log:add` for custom output lines.

---

For further reading, navigate to [Rendering Entities](./rendering_entities.md) or [Registering New Content](./registering_content.md).

