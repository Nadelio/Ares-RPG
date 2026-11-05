# Creating Custom Status Effects

Status effects are temporary pieces of data attached to an entity. The core `StatusSystem` tracks their duration and stacks, while a custom system provides the effect's behavior.

> [!NOTE]
> A status effect never stores a Lua callback. Custom behavior belongs in a system that listens for status lifecycle events.

---

## Status Effect Data

Apply a status effect by emitting `status_apply`:

```lua
Events.emit("status_apply", {
    target = player,
    source = healer,
    effect = {
        id = "regeneration",
        name = "Regeneration",
        duration = 3,
        stacks = 1,
        max_stacks = 3,
        data = {
            amount = 2,
        },
    },
})
```

The event parameters are:
- `target`, the entity receiving the status effect.
- `source`, the entity that applied the status effect (optional).
- `effect`, the status effect's data.

The available status effect fields are:

| Field | Description | Default |
|---|---|---|
| `id` | A unique string used to identify and stack the effect. | Required |
| `name` | The name shown to players. | The effect's `id` |
| `duration` | The number of `turn_end` events before the effect expires. | `1` |
| `stacks` | The number of stacks applied. | `1` |
| `max_stacks` | The maximum number of stacks the effect may have. | `1` |
| `source_id` | The world entity ID that applied the effect. | The `source` entity's ID |
| `data` | Custom data read by the effect's system. | `{}` |

`data` may contain numbers, strings, booleans, and nested tables. It may not contain functions, threads, userdata, or cyclic references.

> [!WARNING]
> The `id` controls stacking. Two mechanically different effects should not share the same ID. For example, use `poison`, `greater_poison`, and `fire_poison` if each effect needs independent duration and stacks.

---

## Creating the Effect System

Create `regeneration.lua` inside your mod's `systems/` folder:

```lua
local Registry = require("core.registry")

local RegenerationSystem = {}

function RegenerationSystem.init(Events, world, map, logger)
    Events.on("status_turn", function(e)
        if e.effect.id ~= "regeneration" then
            return
        end

        local amount = e.effect.data.amount or 1

        Events.emit("heal", {
            target = e.target,
            healer = world.entities[e.effect.source_id],
            amount = amount * e.effect.stacks,
        })
    end, 50)
end

Registry.register("systems", "regeneration", RegenerationSystem)

return RegenerationSystem
```

Every status effect system follows the normal system pattern:
- It has an `init(Events, world, map, logger)` function.
- It listens for one or more status lifecycle events.
- It ignores status IDs that it does not own.
- It registers itself with `Registry.register`.

The mod loader initializes registered systems automatically. You do not need to call `RegenerationSystem.init` from `mod.lua`.

---

## Status Lifecycle Events

The core `StatusSystem` emits three lifecycle events.

### `status_applied`

This event is emitted after a new status is added or an existing status is refreshed.

Parameters:
- `target`, the entity that has the status effect.
- `source`, the entity that applied the status effect when known.
- `effect`, the stored status effect data.

```lua
Events.on("status_applied", function(e)
    if e.effect.id ~= "regeneration" then
        return
    end

    print((e.target.name or "Unknown") .. " begins regenerating.")
end)
```

> [!NOTE]
> `status_applied` is emitted each time the status is applied, including when an existing status gains stacks or has its duration refreshed.

### `status_turn`

This event is emitted once for each active status during `turn_end`. It is emitted before the effect's duration is reduced.

Parameters:
- `target`, the entity that has the status effect.
- `effect`, the stored status effect data.

```lua
Events.on("status_turn", function(e)
    if e.effect.id ~= "regeneration" then
        return
    end

    Events.emit("heal", {
        target = e.target,
        amount = (e.effect.data.amount or 1) * e.effect.stacks,
    })
end)
```

### `status_removed`

This event is emitted after a status reaches `0` duration and is removed.

Parameters:
- `target`, the entity that had the status effect.
- `effect`, the removed status effect data.

```lua
Events.on("status_removed", function(e)
    if e.effect.id ~= "regeneration" then
        return
    end

    print((e.target.name or "Unknown") .. " stops regenerating.")
end)
```

Use this event to remove persistent changes made by the effect or to perform other cleanup.

---

## Stacking and Duration

When `status_apply` receives an effect whose `id` is already active:
1. The incoming stacks are added to the existing stacks.
2. The result is limited to `max_stacks`.
3. The duration becomes the greater of the existing and incoming duration.
4. `status_applied` is emitted with the updated effect.

Only one status entry is stored for each ID.

For example:

```lua
-- Existing effect
{
    id = "regeneration",
    duration = 2,
    stacks = 1,
    max_stacks = 3,
}

-- Incoming effect
{
    id = "regeneration",
    duration = 4,
    stacks = 2,
    max_stacks = 3,
}

-- Updated effect
{
    id = "regeneration",
    duration = 4,
    stacks = 3,
    max_stacks = 3,
}
```

---

## Applying Status Effects From Items

Items use declarative trigger data instead of Lua callbacks. The `ItemEffectSystem` reads this data and emits the configured event.

The following weapon applies poison when it hits a target:

```lua
local Registry = require("core.registry")

local Item = Registry.resolve("components", "item")

local poisoned_blade = Item.new({
    name = "Poisoned Blade",
    description = "Applies poison when it hits an enemy.",
    rarity = "uncommon",

    triggers = {
        on_hit = {
            {
                event = "status_apply",

                data = {
                    effect = {
                        id = "poison",
                        name = "Poison",
                        duration = 3,
                        stacks = 1,
                        max_stacks = 5,

                        data = {
                            damage = 1,
                        },
                    },
                },

                bindings = {
                    source = "owner",
                    target = "target",
                },
            },
        },
    },
})
```

The trigger descriptor contains:
- `event`, the event emitted when the trigger runs.
- `data`, static data copied into the event payload.
- `bindings`, event fields copied from the trigger context.

In this example:
- `source = "owner"` copies the item's owner into the event's `source` field.
- `target = "target"` copies the entity that was hit into the event's `target` field.

The item only applies the status data. A separate poison system must listen for `status_turn` and implement poison's behavior.

Available item trigger names currently include:
- `on_equip`
- `on_unequip`
- `on_interact`
- `on_hit`

> [!NOTE]
> Trigger descriptors are copied before they are emitted. Runtime fields such as `cancelled` and remaining status duration do not modify the original item definition.

---

## Accessing the Source Entity

The `StatusSystem` stores the applying entity's ID in `effect.source_id`. A system may resolve the entity through the world:

```lua
local source = world.entities[e.effect.source_id]

if source then
    print("Applied by " .. (source.name or "Unknown"))
end
```

The source may no longer exist when the status runs, so always check the result before using it.

---

For further reading, navigate to the [Ares ECS Framework](../ecs_framework.md), [Creating Custom Items](./custom_items.md), or [Events Reference](../references/events.md)
