local Registry = require("core.registry")

local DoorPlacer = {}

function DoorPlacer.init(Events, world, map, logger)
    local Door = Registry.resolve("prefabs", "door")
    local door = Door.new({ x = 5, y = 3 })
    map:add_object(door)
end

Registry.register("systems", "door_placer", DoorPlacer)

return DoorPlacer