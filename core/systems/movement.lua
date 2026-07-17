local Registry = require("core.registry")
local MovementRules = require("core.systems.move_rules")
local StatSystem = require("core.systems.stats")

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
        elseif e.entity.stats and e.entity.stats.current.movement == 0 then
            e.cancelled = true
            return
        end

        e.entity.position.x = x
        e.entity.position.y = y

        e.to = { x = x, y = y }
        e.from = { x = x - (e.dx or 0), y = y - (e.dy or 0) }

        if e.entity.stats then
            e.entity.stats.current.movement = math.max(0, e.entity.stats.current.movement - 1)
        end

    end, 100)

    Events.on("turn_end", function(e)
        local entities_with_stamina = world:query(function(entity)
            return (
                entity.stats
                and entity.stats.base
                and entity.stats.base.movement
                and entity.stats.current
                and entity.stats.current.movement
            )
        end)

        for _, entity in ipairs(entities_with_stamina) do
            entity.stats.current.movement = StatSystem.get(entity.stats, "movement")
        end
    end, 100)
end

Registry.register("systems", "movement", MovementSystem)

return MovementSystem 