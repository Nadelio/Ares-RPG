local Input = {}
local queue = {}

function love.keypressed(key, scancode, isrepeat)
    local eventKey = key

    if key == "z" and love.keyboard.isDown("lctrl") then
        eventKey = "ctrl+z"
    end

    table.insert(queue, eventKey)
end

function Input.poll()
    return table.remove(queue, 1)
end

return Input