local Registry = require("core.registry")

local LoggerSystem = {} 

function LoggerSystem.init(Events, world, map, logger)

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

    Events.on("inventory_equip", function(e)
        logger:add("inventory_equip", {
            actor = e.entity.name,
            target = LoggerSystem.safe_item(e.entity, e.index, e.item),
        })
    end, -100)
    Events.on("inventory_unequip", function(e)
        logger:add("inventory_unequip", {
            actor = e.entity.name,
            target = LoggerSystem.safe_item(e.entity, e.index, e.item),
        }) 
    end, -100)
    Events.on("inventory_pickup", function(e)
        logger:add("inventory_pickup", {
            actor = e.actor.name,
            target = e.target.name,
        })
    end, -100)
    Events.on("inventory_drop", function(e)
        logger:add("inventory_drop", {
            actor = e.entity.name,
            target = LoggerSystem.safe_item(e.entity, e.index, e.item),
        })
    end, -100)

    Events.on("level_up", function(e)
        logger:add("level_up", {
            entity = e.entity.name,
            levels = e.amount,
            new_level = e.new_level or e.entity.level,
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

-- HELPERS
function LoggerSystem.safe_item(entity, index, item)
    if item then return item.name or "Unknown" end
    if not entity then return "Unknown" end
    if not entity.inventory then return "Unknown" end
    if not entity.inventory.items then return "Unknown" end
    if not index then return "Unknown" end

    local item = entity.inventory.items[index]
    if not item then return "Unknown" end

    return item.name or "Unknown"
end

Registry.register("systems", "logger", LoggerSystem)

return LoggerSystem 