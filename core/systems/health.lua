local Registry = require("core.registry")
local StatSystem = Registry.resolve("systems", "stats")
local HealthSystem = {}

function HealthSystem.init(Events, world, map, logger)
    Events.on("attack", function(e)

        local entity = e.target
        local amount = e.damage or 0

        if not entity or not entity.stats then
            return
        end

        entity.stats.current.health = math.max(
            0,
            (entity.stats.current.health or StatSystem.get(entity.stats, "health")) - amount
        )

        if entity.stats.current.health <= 0 then
            entity.dead = true
            Events.emit("death", {
                entity = entity
            })
        end

    end, 100)

    Events.on("heal", function(e)

        local entity = e.target
        local amount = e.amount or 0

        if not entity or not entity.stats then
            return
        end

        entity.stats.current.health = math.min(
            StatSystem.get(entity.stats, "health"),
            (entity.stats.current.health or 0) + amount
        )

    end, 100)

end

function HealthSystem.is_alive(entity)
    return entity.stats and entity.stats.current.health > 0
end

Registry.register("systems", "health", HealthSystem)

return HealthSystem