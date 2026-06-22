local Renderable = require("core.components.renderable") 
local Position   = require("core.components.position") 

local Object = {}

function Object.new(data)
    return {
        name = data.name or "Unknown Object",
        type = data.type or "Unknown",

        collides = data.collides or false,
        position = data.position or Position.new(0, 0),

        renderable = data.renderable or Renderable.new("?")
    }
end

return Object