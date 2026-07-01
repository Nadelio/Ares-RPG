local Registry = require("core.registry")

local MovementRules = {}

function MovementRules.can_move(map, x, y)

    local tile = map:get(x, y)

    if not tile or tile.type == "W" then
        return false
    end

    local object = map:get_object(x, y)

    if object and object.collides then
        return false
    end

    return true
end

Registry.register("systems", "move_rules", MovementRules)

return MovementRules