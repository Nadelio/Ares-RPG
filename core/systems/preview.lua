local Registry = require("core.registry")
local GhostSim = require("core.systems.ghost_sim")

local PreviewSystem = {} 

function PreviewSystem.init(Events, world, map, logger)

    Events.on("preview_request", function(e)

        local entity = e.entity
        if not entity or not entity.turn_buffer then return end

        local ghost, preview = GhostSim.run(world, map, entity.turn_buffer:all())

        entity.turn_preview = preview
        entity.turn_ghost = ghost

    end, 50) 

end

Registry.register("systems", "preview", PreviewSystem)

return PreviewSystem 