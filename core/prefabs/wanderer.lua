local Registry = require("core.registry")


local Wanderer = {}

local function isWall(map, x, y)
    if x < 1 or y < 1 then return false end

    local row = map.tiles[y]
    if not row then return false end

    local tile = row[x]
    if not tile then return false end

    return tile.type == "W"
end

function Wanderer.new(data)
    local DynamicObject = Registry.resolve("components", "dynamic_object")
    local Position = Registry.resolve("components", "position")
    local Renderable = Registry.resolve("components", "renderable")
    local PlacementRules = Registry.resolve("components", "placement_rules")
    local Brain = Registry.resolve("components", "brain")
    local Stats = Registry.resolve("components", "stats")

    local dynobj = DynamicObject.new({
        name = "Wanderer",
        type = "npc",
        colldies = true,
        position = Position.new({ x = data.x or 0, y = data.y or 0 }),

        renderable = Renderable.new({ glyph = "W" })
    })

    dynobj.placement_rules = PlacementRules.new({
        valid_placement = function(x, y, map)
            if map.tiles[y][x].type ~= "X" then
                return false
            end

            local walls = {
                TL = isWall(map, x - 1, y - 1),
                TC = isWall(map, x    , y - 1),
                TR = isWall(map, x + 1, y - 1),
                ML = isWall(map, x - 1, y    ),
                MC = isWall(map, x    , y    ),
                MR = isWall(map, x + 1, y    ),
                BL = isWall(map, x - 1, y + 1),
                BC = isWall(map, x    , y + 1),
                BR = isWall(map, x + 1, y + 1),
            }
            
            local corners = {
                TL = walls.TL and walls.TC and walls.ML,
                TR = walls.TR and walls.TC and walls.MR,
                BL = walls.BL and walls.BC and walls.ML,
                BR = walls.BR and walls.BC and walls.MR
            }

            local sides = {
                T = walls.TL and walls.TC and walls.TR,
                L = walls.TL and walls.ML and walls.BL,
                B = walls.BL and walls.BC and walls.BR,
                R = walls.TR and walls.MR and walls.BR
            }

            local none = true
            for _, position in ipairs(walls) do
                if position then none = false; break end
            end

            if none then
                if math.random(0, 100) < 1 then
                    return true
                end
            end
            return false
        end
    })

    dynobj.brain = Brain.new({
        faction = "neutral",
        goals = {
            { priority = 10, type = "wander" }
        }
    })

    dynobj.stats = Stats.new({ health = 1, movement = 1 })

    return dynobj
end

Registry.register("prefabs", "wanderer", Wanderer)

return Wanderer