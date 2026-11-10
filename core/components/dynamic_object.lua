local Registry = require("core.registry")

local DynamicObject = {}

function DynamicObject.new(data)
    local Renderable = Registry.resolve("components", "renderable")
    local Position   = Registry.resolve("components", "position")
    return {
        name = data.name or "Unknown Object",
        type = data.type or "Unknown",

        collides = data.collides or false,
        position = data.position or Position.new({ x = 0, y = 0 }),
        dynamic = true,

        renderable = data.renderable or Renderable.new({ glyph = "?" })
    }
end

Registry.register("components", "dynamic_object", DynamicObject)

return DynamicObject