local Registry = require("core.registry")

local StepCounter = {}

function StepCounter.init(Events, world, map, logger)
    local steps = 0

    Events.on("move", function(e)
        if e.cancelled then return end

        if e.entity ~= world.player then return end

        steps = steps + 1

        if steps % 10 == 0 then
            print("The player has walked " .. steps .. " steps.")
        end
    end)
end

Registry.register("systems", "step_counter", StepCounter)

return StepCounter