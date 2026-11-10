local Registry = require("core.registry")

local Settings = {}

function Settings.new(data)
    return {
        sprite_rendering = data.sprite_rendering or false,
        sprite_resolution = data.sprite_resolution or 16,
    }
end

Registry.register("components", "settings", Settings)

return Settings