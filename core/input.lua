local Input = {}
local queue = {}

function love.keypressed(key, scancode, isrepeat)
    local eventKey = ""

    if love.keyboard.isDown("lctrl") then
        eventKey = eventKey .. "ctrl+"
    end
    if love.keyboard.isDown("lalt") then
        eventKey = eventKey .. "alt+"
    end
    if love.keyboard.isDown("lshift") then
        eventKey = eventKey .. "shift+"
    end

    eventKey = eventKey .. key
    table.insert(queue, eventKey)
end

function Input.poll()
    return table.remove(queue, 1)
end

return Input