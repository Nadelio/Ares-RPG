local HealthSystem = {}

function HealthSystem.init(Events)
    Events.on("attack", function(e)

        local entity = e.target
        local amount = e.damage or 0

        if not entity or not entity.stats then
            return
        end

        entity.stats.current_hp = math.max(
            0,
            (entity.stats.current_hp or entity.stats.health) - amount
        )

        if entity.stats.current_hp <= 0 then
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

        entity.stats.current_hp = math.min(
            entity.stats.health,
            (entity.stats.current_hp or 0) + amount
        )

    end, 100)

end

function HealthSystem.is_alive(entity)
    return entity.stats and entity.stats.current_hp > 0
end

return HealthSystem