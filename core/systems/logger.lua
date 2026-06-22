local LoggerSystem = {} 

function LoggerSystem.init(Events, logger)

    Events.on("move", function(e)
        if e.cancelled then return end

        logger:add("move", {
            entity = e.entity.name,
            from = e.from,
            to = e.to
        })
    end, -100) 

    Events.on("interact", function(e)
        if e.cancelled then return end

        logger:add("interact", {
            actor = e.actor and e.actor.name or "Unknown",
            target = e.target and (e.target.name or "Unknown") or "Unknown",
            type = e.target and (e.target.type or "object") or "object"
        })
    end, -100) 

    Events.on("level_up", function(e)
        logger:add("level_up", {
            entity = e.entity.name,
            levels = e.levels
        })
    end, -100) 

    Events.on("attack", function(e)
        logger:add("attack", {
            attacker = e.attacker.name,
            target = e.target.name,
            damage = e.damage
        })
    end, -100) 

end

return LoggerSystem 