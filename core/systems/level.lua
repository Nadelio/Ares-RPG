local LevelSystem = {} 

function LevelSystem.init(Events)

    Events.on("level_up", function(e)

        local entity = e.target
        local levels = e.amount or 1

        assert(math.type(levels) == "integer", "Cannot add fractional levels")

        entity.level = (entity.level or 0) + levels

    end, 100) 

end

return LevelSystem 