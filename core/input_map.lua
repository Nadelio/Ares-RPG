local InputMap = {}

local actions = {}
local action_order = {}

local function normalize_modifiers(modifiers)
    modifiers = modifiers or {}

    return {
        ctrl = modifiers.ctrl or false,
        alt = modifiers.alt or false,
        shift = modifiers.shift or false,
    }
end

local function modifiers_match(binding_modifiers, modifiers)
    --? Exact match so "w" does not fire while "ctrl+w" is held, and vice versa
    return binding_modifiers.ctrl == (modifiers.ctrl or false)
        and binding_modifiers.alt == (modifiers.alt or false)
        and binding_modifiers.shift == (modifiers.shift or false)
end

function InputMap.add_action(name)
    if actions[name] then
        return
    end

    actions[name] = { events = {} }
    table.insert(action_order, name)
end

function InputMap.has_action(name)
    return actions[name] ~= nil
end

function InputMap.erase_action(name)
    if not actions[name] then
        return
    end

    actions[name] = nil

    for index, action_name in ipairs(action_order) do
        if action_name == name then
            table.remove(action_order, index)
            break
        end
    end
end

function InputMap.get_actions()
    local names = {}

    for _, name in ipairs(action_order) do
        table.insert(names, name)
    end

    return names
end

--? `event` is { key = "w", modifiers = { ctrl = true, alt = false, shift = false } }
function InputMap.action_add_event(name, event)
    InputMap.add_action(name)

    table.insert(actions[name].events, {
        key = event.key,
        modifiers = normalize_modifiers(event.modifiers),
    })
end

function InputMap.action_erase_event(name, event)
    local action = actions[name]

    if not action then
        return
    end

    local modifiers = normalize_modifiers(event.modifiers)

    for index, binding in ipairs(action.events) do
        if binding.key == event.key and modifiers_match(binding.modifiers, modifiers) then
            table.remove(action.events, index)
            return
        end
    end
end

function InputMap.action_erase_events(name)
    if actions[name] then
        actions[name].events = {}
    end
end

function InputMap.action_get_events(name)
    local action = actions[name]

    if not action then
        return {}
    end

    local events = {}

    for _, binding in ipairs(action.events) do
        table.insert(events, {
            key = binding.key,
            modifiers = {
                ctrl = binding.modifiers.ctrl,
                alt = binding.modifiers.alt,
                shift = binding.modifiers.shift,
            },
        })
    end

    return events
end

function InputMap.event_is_action(name, key, modifiers)
    local action = actions[name]

    if not action then
        return false
    end

    for _, binding in ipairs(action.events) do
        if binding.key == key and modifiers_match(binding.modifiers, modifiers or {}) then
            return true
        end
    end

    return false
end

--? returns a fresh set of every action name matched by the keypress: { move_up = true, ... }
function InputMap.get_matches(key, modifiers)
    local matched = {}

    for _, name in ipairs(action_order) do
        if InputMap.event_is_action(name, key, modifiers) then
            matched[name] = true
        end
    end

    return matched
end

--? default bindings, kept separate from runtime state so rebinding can always reset
local defaults = {
    { name = "move_up", events = { { key = "w" } } },
    { name = "move_down", events = { { key = "s" } } },
    { name = "move_left", events = { { key = "a" } } },
    { name = "move_right", events = { { key = "d" } } },

    { name = "ui_up", events = { { key = "up" } } },
    { name = "ui_down", events = { { key = "down" } } },
    { name = "ui_left", events = { { key = "left" } } },
    { name = "ui_right", events = { { key = "right" } } },
    { name = "ui_accept", events = { { key = "e" }, { key = "return" } } },
    { name = "ui_cancel", events = { { key = "q" }, { key = "escape" } } },

    { name = "interact", events = { { key = "e" } } },
    { name = "inventory_toggle", events = { { key = "i" } } },
    { name = "inventory_drop", events = { { key = "q" } } },
    { name = "level_up_toggle", events = { { key = "l" } } },

    { name = "turn_commit", events = { { key = "return" } } },
    { name = "turn_undo", events = { { key = "backspace" } } },
    { name = "turn_clear", events = { { key = "z", modifiers = { ctrl = true } } } },
}

function InputMap.load_defaults()
    actions = {}
    action_order = {}

    for _, default in ipairs(defaults) do
        InputMap.add_action(default.name)

        for _, event in ipairs(default.events) do
            InputMap.action_add_event(default.name, event)
        end
    end
end

InputMap.load_defaults()

return InputMap
