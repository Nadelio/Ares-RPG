local Vec2 = require("core.utils.vector") 

local Position = {} 

function Position.new(x, y)
    return Vec2.new(x, y) 
end

return Position 