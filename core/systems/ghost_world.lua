--? [NOTE]
--? This system was built before I had finished the ECS framework completely,
--?   so it technically breaks the rules of separation,
--?   since it combines both data and code/functions.

local Registry = require("core.registry")
local GhostWorld = {}
GhostWorld.__index = GhostWorld

function GhostWorld.new(world)
    local self = setmetatable({}, GhostWorld) 

    self.entities = {} 

    for _, e in ipairs(world:get_all()) do
        self.entities[e.id] = {
            x = e.position.x,
            y = e.position.y
        } 
    end

    return self 
end

function GhostWorld:get_pos(entity_id)
    return self.entities[entity_id] 
end

function GhostWorld:set_pos(entity_id, x, y)
    if self.entities[entity_id] then
        self.entities[entity_id].x = x 
        self.entities[entity_id].y = y 
    end
end

Registry.register("systems", "ghost_world", GhostWorld)

return GhostWorld 