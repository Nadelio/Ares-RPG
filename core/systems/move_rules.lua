local Registry = require("core.registry")

local MovementRules = {}

function MovementRules.can_move(map, x, y)

    local tile = map:get(x, y)

    if not tile or tile.type == "W" then
        return false
    end

    local objects = map:get_objects(x, y)

    if objects then
        for _, object in ipairs(objects) do
            if object.collides then
                return false
            end
        end
    end

    return true
end

Registry.register("systems", "move_rules", MovementRules)

return MovementRules