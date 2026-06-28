# Events

## Engine
### `tick`
This event is emitted every time the `update()` function is called by Love2D
\Parameters:
- `entity`, the entity that should be affected by the tick (by default this is the player)

### `shutdown`
This event is emitted whenever the game is shutting down
\Parameters: None

## InputSystem
### `input`
This event is emitted on every keypressed event in Love2D
\Parameters:
- `key`, the key pressed
- `entity`, the entity that should be affected by keypress (by default this is the player)

## HealthSystem
### `death`
This event is emitted whenever an entity with the `stats` component has `current.health == 0`
\Parameters:
- `entity`, the entity that died

### `heal`
This event is emitted whenever an entity with the `stas` component increases in health (except for a stat bonus increase)
\Parameters:
- `entity`, the entity healing
- `amount`, the amount of health the entity is healing, defaults to `0`

### `attack`
This event is emitted whenever an entity with the `stats` component decreases in health (except for a stat bonus decrease)
\Parameters:
- `entity`, the entity taking damage
- `amount`, the amount of damage the entity is taking, defaults to `0`

## InventorySystem
### `inventory_add`
This event is emitted whenever an item is inserted directly into an entity's inventory.

> [!WARNING]
> This event is volatile and may delete items if the entity exceeds its carrying capacity.
> Use `inventory_pickup` if you want safer inventory behavior.

\Parameters:
- `entity`, the entity receiving the item
- `item`, the item being added

### `inventory_remove`
This event is emitted whenever an item is removed directly from an inventory.

> [!WARNING]
> This event permanently deletes the item.
> Use `inventory_drop` if you want the item to be placed back into the world.

\Parameters:
- `entity`, the entity losing the item
- `index`, the inventory slot to remove
- `map`, the current game map (optional, used when unequipping items)

### `inventory_pickup`
This event is emitted whenever an entity picks up an item object from the world. If the entity exceeds its carrying capacity, an `inventory_drop` event is emitted automatically.
\Parameters:
- `actor`, the entity picking up the item
- `target`, the world object being picked up
- `map`, the current game map

### `inventory_drop`
This event is emitted whenever an entity drops an item into the world. The item is removed from the inventory and converted into an interactable world object.
\Parameters:
- `entity`, the entity dropping the item
- `index`, the inventory slot to drop
- `map`, the current game map

### `inventory_equip`
This event is emitted whenever an entity equips an item from their inventory. The item's stat modifiers are applied and it is added to the entity's equipped item list.
\Parameters:
- `entity`, the entity equipping the item
- `index`, the inventory slot containing the item
- `map`, the current game map (optional, currently reserved for carry-capacity checks)

### `inventory_unequip`
This event is emitted whenever an entity unequips an equipped item. The item's stat modifiers are removed and it is removed from the equipped item list.
\Parameters:
- `entity`, the entity unequipping the item
- `index`, the inventory slot containing the item
- `map`, the current game map (optional, currently reserved for carry-capacity checks)

## MovementSystem
> [!NOTE]
> Systems may cancel movement by setting `cancelled = true` before the `MovementSystem` executes.
### `move`
This event is emitted whenever an entity attempts to move.
Movement rules are validated before the entity position is updated.
If movement is blocked, the event is cancelled.
\Parameters:
- `entity`, the entity attempting to move
- `dx`, the horizontal movement amount
- `dy`, the vertical movement amount
- `cancelled`, whether movement has been cancelled (optional)

## InteractionSystem
> [!NOTE]
> This is currently not an system separate from anything, it lives purely in [main.lua] and as Events
### `interact`
This event is emitted whenever an entity interacts with an interactable in the world
\Parameters:
- `actor`, the entity that is interacting
- `target`, the interactable the `actor` is interacting with

## TurnSystem
### `turn_commit`
This event is emitted whenever the player commits their turn (by default, this is done via the `enter` key)
\Parameters:
- `entity`, the entity whose turn it is (this should pretty much always be the player)
- `actions`, the array of actions for the turn
- `map`, the current game map

## PreviewSystem
### `preview_request`
This event is emitted whenever the game wants to recompute the turn preview and entity ghost(s)
\Parameters:
- `entity`, the entity whose turn it is (this should be the player most often)
- `actions`, the array of actions for the turn

## LevelSystem
> [!WARNING]
> This system is currently unfinished, and is not recommended for use currently
### `level_up`
This event is emitted whenever an entity levels up
\Parameters:
- `entity`, the entity that leveled up
- `amount`, the amount of levels the entity gained