local Registry = require("core.registry")
local Vec2 = require("core.utils.vector") 

local Position = {} 

function Position.new(data)
    return Vec2.new(data.x or 0, data.y or 0) 
end

Registry.register("components", "position", Position)

return Position 