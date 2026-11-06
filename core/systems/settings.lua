local Registry = require("core.registry")

local Settings = {}

function Settings.init(Events, world, map, logger)
    -- configure settings here based on the settings component
end

Registry.register("systems", "settings", Settings)

return Settings