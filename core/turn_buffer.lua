local TurnBuffer = {} 
TurnBuffer.__index = TurnBuffer 

function TurnBuffer.new()
    return setmetatable({
        actions = {}
    }, TurnBuffer) 
end

function TurnBuffer:add(action)
    table.insert(self.actions, action) 
end

function TurnBuffer:pop()
    return table.remove(self.actions) 
end

function TurnBuffer:clear()
    self.actions = {} 
end

function TurnBuffer:all()

    local copy = {}

    for i, v in ipairs(self.actions) do
        copy[i] = v
    end

    return copy
end

return TurnBuffer 