local Registry = require("core.registry")

local RegenerationStatusEffect = {}

function RegenerationStatusEffect.init(Events, world, map, logger)
    Events.on("status_turn", function(e)
        if e.effect.id ~= "regeneration" then
            return
        end

        Events.emit("heal", {
            target = e.target,
            amount = (e.effect.data.heal_amount or 1) * e.effect.stacks,
        })
    end)
end

Registry.register("systems", "regeneration", RegenerationStatusEffect)

return RegenerationStatusEffect