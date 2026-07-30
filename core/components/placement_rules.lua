local Registry = require("core.registry")

local PlacementRules = {}

function PlacementRules.new(data)
    return {
        valid_tile = data.valid_tile or "X",
        valid_placement = data.valid_placement or function(x, y, map) return false end
    }
end

Registry.register("components", "placement_rules", PlacementRules)

return PlacementRules