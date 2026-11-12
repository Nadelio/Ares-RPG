# Custom Inputs/Keybinds

Ares routes all keyboard input through a Godot-style input action system. Physical keystrokes are matched against named **input actions** registered in `core.input_map`, and gameplay systems respond to action names instead of raw keys.

> [!NOTE]
> Core systems never compare raw key strings. If you want your mod to respect player keybinds, respond to action names too.

---

## How Input Flows

```text
love.keypressed / love.keyreleased
    → core.input matches the key against core.input_map actions
    → the event is queued in press order
    → main.lua polls one event per update and emits "input"
    → core.systems.input routes actions by UI context (menus, chests, gameplay)
```

Every `input` event carries:
- `key`, the raw key combo (e.g. `"e"`, `"ctrl+z"`), kept for mods that need raw keys.
- `actions`, a set of every action name the keypress matched (e.g. `e.actions["interact"] == true`).
- `entity`, the entity receiving the input (the player by default).

---

## Default Actions

| Action | Default Binding(s) | Used For |
|---|---|---|
| `move_up` / `move_down` / `move_left` / `move_right` | `W` / `S` / `A` / `D` | Buffering movement commands |
| `ui_up` / `ui_down` / `ui_left` / `ui_right` | Arrow keys | Menu navigation, tile targeting, inventory slots |
| `ui_accept` | `E`, `Enter` | Confirming menu choices |
| `ui_cancel` | `Q`, `Escape` | Cancelling menus, closing chests |
| `interact` | `E` | Interacting, equipping, transferring items |
| `inventory_toggle` | `I` | Opening/closing the inventory |
| `inventory_drop` | `Q` | Dropping the selected item |
| `level_up_toggle` | `L` | Opening/closing the level-up menu |
| `turn_commit` | `Enter` | Committing the buffered turn |
| `turn_undo` | `Backspace` | Removing the last buffered command |
| `turn_clear` | `Ctrl+Z` | Clearing the turn buffer |

A physical key may match several actions (for example, `E` matches both `interact` and `ui_accept`). The core input system routes by UI context so one keypress never performs conflicting operations.

---

## Registering Custom Actions

Register actions and bindings through `core.input_map`, typically in your mod's `mod.lua` or a system's `init`:

```lua
local InputMap = require("core.input_map")

InputMap.add_action("mymod_cast_spell")
InputMap.action_add_event("mymod_cast_spell", {
    key = "c",
})

InputMap.action_add_event("mymod_cast_spell", {
    key = "c",
    modifiers = { shift = true },
})
```

A binding event contains:
- `key`, the Love2D key constant (e.g. `"c"`, `"f1"`, `"space"`).
- `modifiers`, an optional table of `ctrl`, `alt`, and `shift` booleans. Modifier matching is exact: a plain `"c"` binding does not fire while `Ctrl` is held.

> [!NOTE]
> Prefix your action names with your mod's name (e.g. `mymod_cast_spell`) so they never collide with core or other mods' actions.

Other `InputMap` functions:

| Function | Description |
|---|---|
| `InputMap.has_action(name)` | Returns whether the action exists. |
| `InputMap.get_actions()` | Returns every registered action name in registration order. |
| `InputMap.action_get_events(name)` | Returns a copy of the action's bindings. |
| `InputMap.action_erase_event(name, event)` | Removes one matching binding. |
| `InputMap.action_erase_events(name)` | Removes all of an action's bindings (useful before rebinding). |
| `InputMap.erase_action(name)` | Removes the action entirely. |
| `InputMap.load_defaults()` | Resets every action and binding to the core defaults. |

---

## Responding to Actions

Listen for the `input` event and check the `actions` set:

```lua
local Registry = require("core.registry")

local SpellHotkeySystem = {}

function SpellHotkeySystem.init(Events, world, map, logger)
    Events.on("input", function(e)
        if not e.actions["mymod_cast_spell"] then
            return
        end

        Events.emit("cast_spell", {
            entity = e.entity,
            spell = "firebolt",
        })
    end, 90)
end

Registry.register("systems", "spell_hotkey", SpellHotkeySystem)

return SpellHotkeySystem
```

---

## Polling Action State

`core.input` also exposes Godot-style state queries for held keys:

```lua
local Input = require("core.input")

Input.is_action_pressed("move_up")        --? true while any bound key is held
Input.is_action_just_pressed("move_up")   --? true only on the frame the action was pressed
Input.is_action_released("move_up")       --? true while no bound key is held
Input.is_action_just_released("move_up")  --? true only on the frame the action was released
```

`Input.event_is_action(event, action)` checks a polled input event against an action name.

> [!WARNING]
> Buffered turn commands should come from `input` events, not from polling `is_action_pressed` every tick. Polling a held key every update would rapidly fill the turn buffer.

The `just_pressed`/`just_released` transition flags are cleared at the end of every update, after systems have run. If an action is pressed and released within a single frame, both flags remain visible for that frame. All held actions are released automatically when the game window loses focus.

---

For further reading, navigate to the [Ares ECS Framework](../ecs_framework.md), [Integrating with Core](../integrating_with_core.md), or [Events Reference](../references/events.md)
