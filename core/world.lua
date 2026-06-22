local World = {} 
World.__index = World 

function World.new()
    return setmetatable({
        entities = {},
        next_id = 1
    }, World) 
end

function World:add(entity)
    local id = self.next_id 
    self.next_id = self.next_id + 1 

    entity.id = id 
    self.entities[id] = entity 

    return entity 
end

function World:remove(entity)
    self.entities[entity.id] = nil 
end

function World:get_all()
    local list = {} 

    for _, e in pairs(self.entities) do
        table.insert(list, e) 
    end

    return list 
end

function World:query(filter_fn)
    local result = {} 

    for _, e in pairs(self.entities) do
        if filter_fn(e) then
            table.insert(result, e) 
        end
    end

    return result 
end

return World 