local Registry = require("core.registry")
local MovementRules = require("core.systems.move_rules")
local GhostWorld = require("core.ghost_world")
local GhostSim = {}

function GhostSim.run(world, map, actions)

    local ghost = GhostWorld.new(world)

    local preview = {}

    local entity = world.player
    if not entity then
        return ghost, preview
    end

    for _, action in ipairs(actions) do

        if action.type == "move" then

            local pos = ghost:get_pos(entity.id)

            if pos then
                local nx = pos.x + action.dx
                local ny = pos.y + action.dy

                if MovementRules.can_move(map, nx, ny) then
                    ghost:set_pos(entity.id, nx, ny)
                    table.insert(preview, {
                        type = "move",
                        x = nx,
                        y = ny
                    })
                end
            end
        end
    end

    return ghost, preview
end

Registry.register("systems", "ghost_sim", GhostSim)

return GhostSim