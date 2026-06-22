local Logger = {} 
Logger.__index = Logger 

function Logger.new()
    return setmetatable({
        turn = 1,
        events = {}
    }, Logger) 
end

function Logger:add(eventType, data)
    local entry = {
        turn = self.turn,
        type = eventType,
        data = data or {}
    } 

    table.insert(self.events, entry) 

    self.turn = self.turn + 1 

    return entry 
end

function Logger:next_turn()
    self.turn = self.turn + 1 
end

function Logger:save(path)
    local file = assert(io.open(path, "w")) 

    for _, event in ipairs(self.events) do
        file:write(self:format(event) .. "\n") 
    end

    file:close() 
end

function Logger:format(event)

    if event.type == "move" then
        return string.format(
            "[Turn %d] MOVE %s (%d,%d -> %d,%d)",
            event.turn,
            event.data.entity,
            event.data.from.x, event.data.from.y,
            event.data.to.x, event.data.to.y
        ) 

    elseif event.type == "attack" then
        return string.format(
            "[Turn %d] ATTACK %s -> %s (%d dmg)",
            event.turn,
            event.data.attacker,
            event.data.target,
            event.data.damage
        ) 

    elseif event.type == "interact" then
        return string.format(
            "[Turn %d] INTERACT %s -> %s (%s)",
            event.turn,
            event.data.actor,
            event.data.target,
            event.data.type
        ) 

    elseif event.type == "level_up" then
        return string.format(
            "[Turn %d] LEVEL UP %s (+%s %d)",
            event.turn,
            event.data.entity,
            event.data.stat,
            event.data.amount
        ) 
    end

    return string.format(
        "[Turn %d] %s",
        event.turn,
        event.type
    ) 
end

return Logger 