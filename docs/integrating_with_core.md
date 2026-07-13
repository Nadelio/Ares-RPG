# Integrating with `core`/built-in content

> [!NOTE]
> This guide assumes you have read [Extending Existing Content](./extending_content.md) and [Registering New Content](./registering_content.md). If you haven't, head there first.

This guide goes over the basics of modifying, extending, and using the Ares `core` components, systems, and prefabs, by the end of this guide you should know how to overwrite `core` content, add new fields and functions to `core` content, and use various `core` components and prefabs to build your own mods that work seamlessly with Ares.

---

## General Information

All of Ares's built-in content (components, systems, and prefabs), live in the `core/` folder and are registered under `"components"`, `"systems"`, and `"prefabs"` respectively. You can access any of them with `Registry.resolve` after `Loader.load_core_content()` has run, which happens before any mod `init` is called.

There are three ways you will typically interact with `core` content from a mod:

| Approach | How to use |
|---|---|
| Resolve and use | Call `Registry.resolve` to get a component constructor or system helper and use it directly in your mod code |
| Emit to a system | Trigger `core` system behavior by emitting the events that system listens to, without calling the system directly |
| Extend or overwrite | Wrap or replace a component constructor or system via `Registry.overwrite` (covered in [Extending Existing Content](./extending_content.md)) |

Resolving and emitting are the two approaches you will use most of the time. Direct calls into a system table are only appropriate for stateless helper functions (like `StatSystem.get`), never call an `init` function of a `core` system from a mod.

---

## Using `core` components

Core components are plain data constructors. Resolve them once at the top of your system or prefab file, then call `.new(data)` whenever you need an instance.

### `position`

```lua
local Position = Registry.resolve("components", "position")

local pos = Position.new({ x = 5, y = 3 })
-- pos.x == 5, pos.y == 3
```

> [!NOTE] 
> `Position.new` returns a `Vec2`, so all vector operations (`vec:clone()`, field access, etc.) are available on the result.

### `renderable`

```lua
local Renderable = Registry.resolve("components", "renderable")
local Colors     = require("core.render.colors")

local r = Renderable.new({
    glyph = "T",
    fg    = Colors.orange,
})
```

| Field | Default | Description |
|---|---|---|
| `glyph` | `"?"` | The character drawn on the map |
| `fg` | `Colors.reset` (white) | Foreground colour as an `{r, g, b}` table |
| `bg` | `Colors.black` | Background colour |
| `italics` | `false` | Italic text style |
| `bold` | `false` | Bold text style |
| `underline` | `false` | Underline text style |

Available colours are in `core.render.colors`: `red`, `orange`, `yellow`, `green`, `blue`, `gray`, `black`, `reset`, `cursor`.

> [!NOTE]
> More information available in [Rendering Entities](/docs/rendering_entities.md)

### `item`

```lua
local Item         = Registry.resolve("components", "item")
local RarityColors = require("core.render.raritycolors")

local sword = Item.new({
    name        = "Iron Sword",
    description = "A simple iron sword.",
    rarity      = RarityColors.uncommon,
    size        = 1,
    bonuses     = { attack = 3 },
})
```

| Field | Default | Description |
|---|---|---|
| `name` | `"Unknown Item"` | Display name |
| `description` | `""` | Tooltip or flavour text |
| `rarity` | `"cursed"` | A value from `core.render.raritycolors` |
| `size` | `1` | How many capacity slots the item occupies |
| `bonuses` | `{}` | Stat additions/subtractions applied when the item is equipped |

Available rarities are in `core.render.raritycolors`: `common`, `uncommon`, `rare`, `epic`, `legendary`, `cursed`. Items with the `cursed` rarity render in italics automatically. (Custom rarities can be added)

### `stats`

```lua
local Stats = Registry.resolve("components", "stats")

local stats = Stats.new({
    class   = "warrior",
    health  = 20,
    attack  = 5,
    defense = 2,
    movement = 3,
    luck     = 1,
    capacity = 6,
})
```

`Stats.new` returns a table with three sub-tables:

| Sub-table | Contents |
|---|---|
| `stats.base` | The unmodified starting values |
| `stats.bonuses` | Accumulated equipment/effect bonuses (managed by `StatSystem`) |
| `stats.current` | Mutable values for `health`, `movement`, and `capacity` |

Never write to `stats.base` or `stats.bonuses` directly. Use `StatSystem` helpers instead (see [Using `core` systems](#using-core-systems) below).

### `interactable`

```lua
local Interactable = Registry.resolve("components", "interactable")

local door = Interactable.new({
    interact_func = function(self, e)
        local actor = e.actor
        -- toggle a flag on the actor or the entity itself
        self.open = not self.open
    end
})
```

`interact_func` receives `(self, e)`, where `self` is the entity the component belongs to, and `e` is the `interact` event. If the entity's `interact_func` is `nil`, the interact event still fires but nothing happens.

### `object`

`object` is the base component for world objects (things placed on the map that are not living entities):

```lua
local Object   = Registry.resolve("components", "object")
local Position = Registry.resolve("components", "position")

local barrel = Object.new({
    name      = "Barrel",
    type      = "container",
    collides  = true,
    position  = Position.new({ x = 4, y = 7 }),
    renderable = Renderable.new({ glyph = "O", fg = Colors.orange }),
})
```

Setting `collides = true` prevents entities from walking through the object.

---

## Using `core` systems

`core` systems expose two interfaces. Some have public helper functions you can call directly. All of them respond to events you can emit.

### StatSystem helper functions

`core.systems.stats` exposes several stateless helper functions for reading and modifying stat data:

```lua
local StatSystem = Registry.resolve("systems", "stats")

-- Get the effective value of a stat (base + bonuses)
local total_attack = StatSystem.get(entity.stats, "attack")

-- Apply a set of bonuses (e.g. when equipping an item)
StatSystem.equip(entity.stats, item)

-- Remove a set of bonuses (e.g. when unequipping an item)
StatSystem.unequip(entity.stats, item)

-- Directly set a base stat value
StatSystem.setBase(entity.stats, "health", 30)

-- Adjust a base stat by an amount
StatSystem.modifyBase(entity.stats, "attack", 2)
```

`StatSystem.get` is the correct way to read a stat's effective value. Never add `stats.base[stat]` and `stats.bonuses[stat]` yourself, `get` handles `nil` bonuses correctly.

### HealthSystem helpers

`core.systems.health` exposes one public helper function:

```lua
local HealthSystem = Registry.resolve("systems", "health")

if HealthSystem.is_alive(entity) then
    -- entity has stats and current health > 0
end
```

To deal damage or heal, emit the appropriate event rather than modifying `stats.current.health` directly:

```lua
-- Deal damage
Events.emit("attack", {
    target   = entity,
    attacker = source_entity,  -- optional
    damage   = 5,
})

-- Heal
Events.emit("heal", {
    target = entity,
    amount = 3,
})
```

`HealthSystem` will clamp health to `[0, max]` and emit `death` automatically if health reaches zero.

### InventorySystem via events

Never insert items into `inventory.items` directly. Use the inventory events so capacity checks and stat bonuses are applied correctly:

```lua
-- Add an item to an entity's inventory (volatile, may discard the last item if over capacity)
Events.emit("inventory_add", {
    entity = entity,
    item   = item,
})

-- Safer pickup: picks up a world object, automatically drops the last item if over capacity
Events.emit("inventory_pickup", {
    actor  = entity,
    target = world_object,  -- must have a .item field
    map    = map,
})

-- Drop an item back into the world
Events.emit("inventory_drop", {
    entity = entity,
    index  = slot_index,
    map    = map,
})

-- Equip an item in a given slot
Events.emit("inventory_equip", {
    entity = entity,
    index  = slot_index,
})

-- Unequip an equipped item
Events.emit("inventory_unequip", {
    entity = entity,
    index  = slot_index,
})
```

> [!WARNING]
> `inventory_add` will silently remove the last item in the inventory if adding the new item would exceed the entity's carrying capacity. If you are picking up world objects, prefer `inventory_pickup`, it emits an `inventory_drop` instead, which places the displaced item back on the map rather than destroying it.

---

## Using `core` prefabs

Prefabs are pre-assembled groups of components. Resolve and instantiate them with `.new(data)`, then add the result to the map or the world as needed.

### `chest`

```lua
local Chest = Registry.resolve("prefabs", "chest")

local my_chest = Chest.new({ x = 8, y = 4 })
map:add_object(my_chest)
```

A chest is an `object` with `collides = true`, a `loot_table` component, and an `interactable` that opens the chest inventory UI when the player interacts with it. The `loot_table.valid_items` table is empty by default, pass in a table of items to it in your mod to define what the chest can contain.

To pre-fill a chest's inventory directly:

```lua
local item = Item.new({ name = "Gold Coin", rarity = RarityColors.common, size = 1, bonuses = {} })
table.insert(my_chest.loot_table.inventory.items, item)
```

> [!NOTE]
> The `loot_table` system that automatically rolls items into `valid_items` is still WIP. For now, inserting into `loot_table.inventory.items` directly is the supported way to pre-fill a container. (THIS METHOD WILL BE DEPRECIATED LATER)

---

## Adding fields to `core` entities

Sometimes you need to attach new data to an entity that already has `core` components, without changing how those components are constructed globally. Patch the entity table directly after you create it:

```lua
Events.on("build_map", function(e)
    local enemy = world:add({
        name       = "Cursed Knight",
        position   = Position.new({ x = 10, y = 5 }),
        renderable = Renderable.new({ glyph = "K", fg = Colors.red }),
        stats      = Stats.new({ health = 15, attack = 4, defense = 1 }),
    })

    -- attach mod-specific data directly on the entity
    enemy.cursed          = true
    enemy.curse_stack     = 3
    enemy.curse_damage    = 1
end)
```

You can then read these fields from any event that receives the entity:

```lua
Events.on("death", function(e)
    if e.cancelled then return end
    if e.entity.cursed then
        -- spread the curse to the killer
        if e.entity.killer then
            e.entity.killer.curse_stack = (e.entity.killer.curse_stack or 0) + 1
        end
    end
end)
```

> [!WARNING]
> Do not patch fields that `core` systems write to (`stats.current.health`, `position.x`, `position.y`, etc.) from inside an unrelated event receiver. You risk overwriting values the `core` system set in the same frame.

---

## Table of Contents

- [Custom Items](./core/custom_items.md)
- [Custom Stats](./core/custom_stats.md)
- [Custom Rarities](./core/custom_rarities.md)
- [Custom Classes](./core/custom_classes.md)
- [Custom Spells](./core/custom_spells.md)
- [Custom Skills](./core/custom_skills.md)
- [Custom Inputs/Keybinds](./core/custom_inputs.md)
- [Custom UI Elements](./core/custom_ui.md)
- [Custom Entities](./core/custom_entities.md)
- [Procedural Map Generation](./core/procedural_map_gen.md)
- [Custom Objects](./core/custom_objects.md)
- [Custom Tile Styles](./core/custom_tile_styles.md)
- [Custom Loot Tables](./core/custom_loot_tables.md)
- [Custom Floors](./core/custom_floors.md)
- [New Movement Rules](./core/extending_move_rules.md)
- [Adding New Actions](./core/extending_turn_buffer.md)
- [Custom Notifications](./core/custom_notifications.md)
- [Custom Achievements](./core/custom_achievments.md)