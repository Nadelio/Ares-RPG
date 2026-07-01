local Registry = require("core.registry")
local MovementRules = Registry.resolve("systems", "move_rules") 

local MovementSystem = {} 

function MovementSystem.init(Events, world, map, logger)

    Events.on("move", function(e)

        if e.cancelled then return end
        if not e.entity or not e.entity.position then return end

        local x = e.entity.position.x + (e.dx or 0)
        local y = e.entity.position.y + (e.dy or 0)

        if not MovementRules.can_move(map, x, y) then
            e.cancelled = true
            return
        end

        e.entity.position.x = x
        e.entity.position.y = y

        e.to = { x = x, y = y }
        e.from = { x = x - (e.dx or 0), y = y - (e.dy or 0) }

    end, 100) 

end

Registry.register("systems", "movement", MovementSystem)

return MovementSystem 