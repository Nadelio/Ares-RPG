local Registry = require("core.registry")

local Object = {}

function Object.new(data)
    local Renderable = Registry.resolve("components", "renderable")
    local Position   = Registry.resolve("components", "position")
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