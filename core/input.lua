local InputMap = require("core.input_map")

local Input = {}

local queue = {}
local states = {}

local function get_state(action)
    local state = states[action]

    if not state then
        state = {
            held_keys = {},
            held_count = 0,
            pressed = false,
            just_pressed = false,
            just_released = false,
        }
        states[action] = state
    end

    return state
end

local function current_modifiers()
    return {
        ctrl = love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl"),
        alt = love.keyboard.isDown("lalt") or love.keyboard.isDown("ralt"),
        shift = love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift"),
    }
end

local function combo_string(key, modifiers)
    local combo = ""

    if modifiers.ctrl then
        combo = combo .. "ctrl+"
    end
    if modifiers.alt then
        combo = combo .. "alt+"
    end
    if modifiers.shift then
        combo = combo .. "shift+"
    end

    return combo .. key
end

function love.keypressed(key, scancode, isrepeat)
    local modifiers = current_modifiers()
    local matched = InputMap.get_matches(key, modifiers)

    for action in pairs(matched) do
        local state = get_state(action)

        if not state.held_keys[key] then
            state.held_keys[key] = true
            state.held_count = state.held_count + 1
        end

        if not state.pressed then
            state.pressed = true
            state.just_pressed = true
        end
    end

    --? unmatched keys are still queued so mods can react to raw keys
    table.insert(queue, {
        key = combo_string(key, modifiers),
        actions = matched,
    })
end

function love.keyreleased(key, scancode)
    for _, state in pairs(states) do
        if state.held_keys[key] then
            state.held_keys[key] = nil
            state.held_count = state.held_count - 1

            --? releasing one key must not release the action while another bound key is held
            if state.held_count <= 0 and state.pressed then
                state.held_count = 0
                state.pressed = false
                state.just_released = true
            end
        end
    end
end

function love.focus(focused)
    if focused then
        return
    end

    --? release everything on when player clicks off game so actions cannot remain stuck
    for _, state in pairs(states) do
        if state.pressed then
            state.pressed = false
            state.just_released = true
        end

        state.held_keys = {}
        state.held_count = 0
    end
end

--? returns the next queued input event in press order: { key = "ctrl+z", actions = { turn_clear = true } }
function Input.poll()
    return table.remove(queue, 1)
end

function Input.event_is_action(event, action)
    return event ~= nil and event.actions ~= nil and event.actions[action] == true
end

function Input.is_action_pressed(action)
    local state = states[action]

    return state ~= nil and state.pressed
end

function Input.is_action_just_pressed(action)
    local state = states[action]

    return state ~= nil and state.just_pressed
end

function Input.is_action_released(action)
    return not Input.is_action_pressed(action)
end

function Input.is_action_just_released(action)
    local state = states[action]

    return state ~= nil and state.just_released
end

--? clears frame-local transition flags, called once at the end of every update
function Input.end_frame()
    for _, state in pairs(states) do
        state.just_pressed = false
        state.just_released = false
    end
end

return Input