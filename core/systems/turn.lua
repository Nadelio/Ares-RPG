local Registry = require("core.registry")

local TurnSystem = {} 

function TurnSystem.init(Events, world, map, logger)
    local InteractionSystem = Registry.resolve("systems", "interaction")
    local pending_turn

    local function finish_turn()
        Events.emit("turn_end", {})
    end

    local process_actions

    process_actions = function(commit, start_index)
        for index = start_index or 1, #commit.actions do
            local action = commit.actions[index]

            if action.type == "move" then
                Events.emit("move", {
                    entity = commit.entity,
                    dx = action.dx,
                    dy = action.dy
                }) 

            elseif action.type == "interact" then
                local entity = commit.entity
                local target = InteractionSystem.get_target(world, commit.map, entity, action.tile)

                if target then
                    local result = Events.emit("interact", {
                        actor = entity,
                        target = target,
                        map = commit.map,
                        events = Events,
                    })

                    if result.pending then
                        pending_turn = {
                            commit = commit,
                            next_index = index + 1,
                        }
                        return
                    end
                end
            end
        end

        finish_turn()
    end

    Events.on("turn_commit", function(e)
        if pending_turn then
            e.cancelled = true
            return
        end

        process_actions(e, 1)
    end, 100)

    Events.on("interaction_resolved", function(e)
        if not pending_turn or pending_turn.commit.entity ~= e.actor then
            return
        end

        local turn = pending_turn
        pending_turn = nil
        process_actions(turn.commit, turn.next_index)
    end, 100)

end

Registry.register("systems", "turn", TurnSystem)

return TurnSystem 