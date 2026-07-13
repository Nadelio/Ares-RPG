# Extending Existing Content

> [!NOTE]
> This guide assumes you have read [Registering New Content](./registering_content.md) and are familiar with [Your First Mod](./first_mod.md), if you haven't, head there first.

There are three main ways to extend or modify content that already exists in Ares:

| Method | Use case |
|---|---|
| Event interception | Add behaviour around an existing action without touching its system |
| Registry overwrite | Replace an entire system, component, or prefab with your own version |
| Entity patching | Add new fields to an entity's component data at runtime |

This guide walks through each approach with some guidelines and common mistakes.

---

## Event Interception

This is the safest and most composable way to extend existing behavior. Instead of replacing core systems, you subscribe to the same events they do and run your code before, after, or instead of theirs.

### Running code before a core system

Use a high priority number (higher than core's `100`) to fire your listener first:

```lua
Events.on("move", function(e)
    if e.cancelled then return end

    -- cancel movement into a poison tile before MovementSystem resolves it
    local target_tile = map:get_tile(
        e.entity.position.x + (e.dx or 0),
        e.entity.position.y + (e.dy or 0)
    )

    if target_tile and target_tile.type == "poison" then
        e.cancelled = true
        logger:add("You refuse to step into the toxic sludge.")
    end
end, 200) -- runs before core's movement at 100
```

### Running code after a core system

Use a negative or lower priority to fire your listener after the core systems have already resolved:

```lua
Events.on("move", function(e)
    if e.cancelled then return end

    -- e.to is set by core's MovementSystem, so this only runs after the move succeeds
    logger:add("Moved to (" .. e.to.x .. ", " .. e.to.y .. ")")
end, -50) -- runs well after core's movement at 100
```

### Using `Events.before` and `Events.after`

For the common case of explicitly hooking the start or end of an event chain, Ares provides two helpers:

```lua
-- Equivalent to Events.on("before:attack", fn, 200)
Events.before("attack", function(e)
    -- runs before any attack listener, including core's health system
    print("Attack is about to happen!")
end)

-- Equivalent to Events.on("after:attack", fn, -200)
Events.after("attack", function(e)
    if e.cancelled then return end
    -- runs after all normal attack listeners have finished
    print("Attack resolved.")
end)
```

> [!NOTE]
> `Events.before` and `Events.after` are purely priority shortcuts. They do not form a separate call stack, they are still part of the same `emit` chain. Cancellation works the same way.

---

## Registry Overwrite

Use `Registry.overwrite` when you need to replace a system, component, or prefab entirely. Unlike `Registry.register`, it will not error on duplicates, it replaces the existing entry and prints a warning to the console.

```lua
Registry.overwrite(category, name, value)
```

### Replacing a system

The example below replaces `core.systems.movement` with a version that adds a stamina cost every time the player moves:

```lua
local Registry = require("core.registry")
local MovementRules = require("core.systems.move_rules")

local StaminaMovement = {}

function StaminaMovement.init(Events, world, map, logger)
    Events.on("move", function(e)
        if e.cancelled then return end
        if not e.entity or not e.entity.position then return end

        local x = e.entity.position.x + (e.dx or 0)
        local y = e.entity.position.y + (e.dy or 0)

        if not MovementRules.can_move(map, x, y) then
            e.cancelled = true
            return
        end

        -- deduct stamina before committing the move
        if e.entity.stats and e.entity.stats.current.stamina then
            if e.entity.stats.current.stamina <= 0 then
                e.cancelled = true
                logger:add("Too exhausted to move.")
                return
            end
            e.entity.stats.current.stamina = e.entity.stats.current.stamina - 1
        end

        e.entity.position.x = x
        e.entity.position.y = y

        e.to   = { x = x, y = y }
        e.from = { x = x - (e.dx or 0), y = y - (e.dy or 0) }
    end, 100)
end

-- replaces core's movement system globally
Registry.overwrite("systems", "movement", StaminaMovement)

return StaminaMovement
```

> [!WARNING]
> Overwriting replaces the entry globally. Every system and mod that calls `Registry.resolve("systems", "movement")` will now receive your version, if your replacement does not faithfully re-implement the contract of the original (e.g. it forgets to set `e.to` and `e.from`), systems that depend on those fields will break silently.

### Replacing a component constructor

You can also overwrite a component to add new default fields, useful when you want every entity that uses that component to have your new data automatically:

```lua
local Registry = require("core.registry")
local Vec2 = require("core.utils.vector")

-- wrap the original Stats.new to add a stamina field
local Stats = Registry.resolve("components", "stats")

local ExtendedStats = {}
ExtendedStats.definitions = Stats.definitions
ExtendedStats.definition_map = Stats.definition_map
ExtendedStats.get_definition = Stats.get_definition

function ExtendedStats.new(data)
    local stats = Stats.new(data)

    -- add the new stamina fields alongside the existing ones
    stats.base.stamina    = data.stamina or 10
    stats.current.stamina = data.stamina or 10

    return stats
end

Registry.overwrite("components", "stats", ExtendedStats)

return ExtendedStats
```

> [!NOTE]
> When wrapping a component constructor like this, always copy over any static fields (`definitions`, `definition_map`, helper functions) from the original. Other systems may depend on them and will not find them if you return a bare table.

---

## Entity Patching

Sometimes you don't want to change how a component is constructed globally, you just need to add a field to a specific entity after it has already been created. You can do this directly on the entity table at any point, including during event receivers.

```lua
Events.on("death", function(e)
    if e.cancelled then return end

    -- mark the entity as a ghost candidate by patching it directly
    e.entity.ghost_eligible = true
    e.entity.ghost_timer    = 5
end)
```

Patching is safe for one-off data that only your mod uses, if the field needs to survive across multiple systems or events, consider creating a proper component instead.

> [!WARNING]
> Do not patch component fields that core systems write to (like `stats.current.health`) from inside an unrelated event receiver. You risk creating a race condition where the core system overwrites your value in the same frame.

---

## Guidelines

- Prefer event interception over overwriting. Adding a new `Events.on` listener is fully additive, overwriting breaks any other mod that also depends on the original entry.
- Always check `e.cancelled` first, if another listener has already cancelled the event, your logic should not run. This is the single most common source of hidden bugs.
- Use priority intentionally, if you need to run before a core system, use a number above `100`, if you just need to observe a completed action, use `0` or lower.
- Copy static fields when wrapping constructors. Component tables often carry lookup tables and helper functions alongside `new()`. Leave them intact.
- Overwrite at load time. Do all `Registry.overwrite` calls at module load (outside of `init`), never conditionally or mid-game. The Registry is a global shared table, mutating it after startup leads to hard to find bugs.
- Emit `before:` and `after:` events consistently, if your system adds new events, follow the same convention so other mods can hook them cleanly.

---

## Common Mistakes

### Forgetting `e.cancelled`

```lua
-- runs even on cancelled moves, causing hidden effects
Events.on("move", function(e)
    play_footstep_sound()
end)

-- make sure to early return if the event gets cancelled
Events.on("move", function(e)
    if e.cancelled then return end
    play_footstep_sound()
end)
```

### Using `register` when you mean `overwrite`

```lua
-- errors at startup with "Duplicate: movement" if core already registered it
Registry.register("systems", "movement", MySystem)

-- overwrite if you want to replace or extend an existing system
Registry.overwrite("systems", "movement", MySystem)
```

### Overwriting without preserving the contract

If core's `move` handler sets `e.to` and `e.from`, and your overwrite skips that, any downstream listener that reads `e.to` will get `nil` and may crash or silently do nothing. Read the source of whatever you are replacing before you write the replacement.

### Patching inside the wrong event

```lua
-- "tick" fires every frame, this adds a new table entry 60 times per second
Events.on("tick", function(e)
    e.entity.my_mod_data = e.entity.my_mod_data or {}
    table.insert(e.entity.my_mod_data, { frame = love.timer.getTime() })
end)
```

Patch once at creation time (in a `prefab.new` or in response to a one-shot event like `spawn`) rather than on every tick.

### Priority conflicts with other mods

If two mods both register at priority `200` for the same event, execution order between them is undefined. Document the priorities your mod uses and leave gaps so other mods can slot in around you.

---

## Example: Poison Tiles

This example adds a new tile type `"poison"` that damages the player on every step.

`systems/poison.lua`
```lua
local Registry = require("core.registry")

local PoisonSystem = {}

function PoisonSystem.init(Events, world, map, logger)

    -- intercept movement BEFORE the core system resolves it (priority > 100)
    Events.on("move", function(e)
        if e.cancelled then return end
        if not e.entity or not e.entity.position then return end

        local tx = e.entity.position.x + (e.dx or 0)
        local ty = e.entity.position.y + (e.dy or 0)
        local tile = map:get_tile(tx, ty)

        if tile and tile.type == "poison" then
            -- allow the move, but schedule damage for after it resolves
            e.entity.poisoned = true
        end
    end, 150)

    -- apply the damage AFTER the move has committed (priority < 100)
    Events.on("move", function(e)
        if e.cancelled then return end
        if not e.entity or not e.entity.poisoned then return end

        e.entity.poisoned = nil

        Events.emit("attack", {
            target   = e.entity,
            attacker = nil,
            damage   = 2,
        })

        logger:add("The poison burns your feet!")
    end, 50)

end

Registry.register("systems", "poison", PoisonSystem)

return PoisonSystem
```

> [!NOTE]
> The two-listener pattern here (one at priority `150`, one at priority `50`) lets you split "detect" from "apply" cleanly and keeps each listener focused on a single part of the system.

---

## Example: Extending the Chest Prefab

This example wraps `core.prefabs.chest` to produce a locked chest variant that requires a key item before it can be opened.

`prefabs/locked_chest.lua`
```lua
local Registry   = require("core.registry")
local Chest      = Registry.resolve("prefabs", "chest")
local Interactable = require("core.components.interactable")

local LockedChest = {}

function LockedChest.new(data)
    -- build a normal chest first
    local obj = Chest.new(data)

    obj.locked = true

    -- replace its interact function with a lock-checking version
    obj.interactable = Interactable.new({
        interact_func = function(entity, e)
            local actor = e.actor
            if not actor or not actor.inventory then return end

            if obj.locked then
                -- search the actor's inventory for a key
                local has_key = false
                for _, item in ipairs(actor.inventory.items) do
                    if item.key_type == "chest_key" then
                        has_key = true
                        break
                    end
                end

                if not has_key then
                    -- emit an event so other systems (logger, UI) can react
                    Events.emit("interact_blocked", {
                        actor  = actor,
                        target = entity,
                        reason = "locked",
                    })
                    return
                end

                obj.locked = false
            end

            -- once unlocked, delegate to the original chest behavior
            Chest.new(data).interactable.interact(entity, e)
        end,
    })

    return obj
end

Registry.register("prefabs", "locked_chest", LockedChest)

return LockedChest
```

> [!NOTE]
> This pattern, resolve the original prefab, call its `new`, then swap out one component, is the cleanest way to build variants. Any changes to the base prefab will be added to the extended prefab automatically.

---

For further reading, navigate to [Working With `core` Content](./integrating_with_core.md) or the [Events Reference](./references/events.md).
