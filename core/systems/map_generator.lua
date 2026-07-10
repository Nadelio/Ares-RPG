local Registry = require("core.registry")

local MapGenerator = {}

function MapGenerator.init(Events, world, map, logger)
    Events.on("build_map", function(e)
        local valid_objs = Registry.query("prefabs", function(prefab)
            return (prefab.name and prefab.type) -- TODO: verify that this grabs all prefabs that are Objects
        end)
        local new_map = {}
        -- TODO: build map based on structure rules and binary space partitioning
        -- TODO: structure rules are room layouts, their corridor locations, and valid rotations
        map = new_map --! need to figure out how to modify map passed in through init() and not make a local map variable
    end, 100)
end

Registry.register("systems", "map_generator", MapGenerator)

return MapGenerator