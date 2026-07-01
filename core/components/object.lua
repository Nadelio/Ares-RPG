local Registry = require("core.registry")
local Renderable = require("core.components.renderable")
local Position   = require("core.components.position")

local Object = {}

function Object.new(data)
    return {
        name = data.name or "Unknown Object",
        type = data.type or "Unknown",

        collides = data.collides or false,
        position = data.position or Position.new({ x = 0, y = 0 }),

        renderable = data.renderable or Renderable.new({ glyph = "?" })
    }
end

Registry.register("components", "object", Object)

return Object