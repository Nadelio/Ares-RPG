# Events

## Engine
### `tick`
This event is emitted every time the `update()` function is called by Love2D
Parameters:
- `entity`, the entity that should be affected by the tick (by default this is the player)

### `shutdown`
This event is emitted whenever the game is shutting down
Parameters: None

## InputSystem
### `input`
This event is emitted on every keypressed event in Love2D
Parameters:
- `key`, the key pressed
- `entity`, the entity that should be affected by keypress (by default this is the player)

## HealthSystem
### `death`
This event is emitted whenever an entity with the `stats` component has `current.health == 0`
Parameters:
- `entity`, the entity that died

### `heal`
This event is emitted whenever an entity with the `stas` component increases in health (except for a stat bonus increase)
Parameters:
- `entity`, the entity healing
- `amount`, the amount of health the entity is healing, defaults to `0`

### `attack`
This event is emitted whenever an entity with the `stats` component decreases in health (except for a stat bonus decrease)
Parameters:
- `entity`, the entity taking damage
- `amount`, the amount of damage the entity is taking, defaults to `0`

## InventorySystem
### `inventory_add`
### `inventory_remove`
### `inventory_pickup`
### `inventory_drop`
### `inventory_equip`
### `inventory_unequip`

## MovementSystem
### `move`

## InteractionSystem
> [!NOTE]
> This is currently not an system separate from anything, it lives purely in [main.lua] and as Events
### `interact`

## TurnSystem
### `turn_commit`

## PreviewSystem
### `preview_request`

## LevelSystem
> [!WARNING]
> This system is currently unfinished
### `level_up`