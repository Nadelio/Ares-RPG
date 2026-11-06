local Registry = require("core.registry")

local Initializer = {}

function Initializer.init(Events, world, map, logger)
    local UISystem = Registry.resolve("systems", "ui")
    UISystem.clear_widgets()
end

Registry.overwrite("systems", "game", Initializer)

return Initializer