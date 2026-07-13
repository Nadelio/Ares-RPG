local Registry = require("core.registry")

local TurnSystem = {} 

function TurnSystem.init(Events, world, map, logger)

    Events.on("turn_commit", function(e)

        for _, action in ipairs(e.actions) do

            if action.type == "move" then
                Events.emit("move", {
                    entity = e.entity,
                    dx = action.dx,
                    dy = action.dy
                }) 

            elseif action.type == "interact" then
                local entity = e.entity
                local target = e.map:get_adjacent_interactable(
                    -- entity position
                    entity.position.x,
                    entity.position.y,
                    -- direction
                    action.tile.x,
                    action.tile.y
                )

                if target then
                    Events.emit("interact", {
                        actor = entity,
                        target = target,
                        map = e.map
                    })
                end
            end

        end

        Events.emit("turn_end", {})

    end, 100) 

    

end

Registry.register("systems", "turn", TurnSystem)

return TurnSystem 