local Registry     = require("core.registry")

local TileStyles   = require("core.render.tile_styles")
local Colors       = require("core.render.colors")

local Door = {}

local function isCorridor(map, x, y)
    if x < 1 or y < 1 then return false end

    local row = map.tiles[y]
    if not row then return false end

    local tile = row[x]
    if not tile then return false end

    return tile.type == "C"
end

function Door.new(data)
    local Object         = Registry.resolve("components", "object")
    local Position       = Registry.resolve("components", "position")
    local Renderable     = Registry.resolve("components", "renderable")
    local Interactable   = Registry.resolve("components", "interactable")
    local PlacementRules = Registry.resolve("components", "placement_rules")

    local obj = Object.new({
        name       = data.name or "Door",
        type       = "door",
        collides   = true,
        position   = Position.new({ x = data.x or 0, y = data.y or 0 }),
        renderable = Renderable.new({ glyph = "+", fg = Colors.yellow }),
    })

    obj.interactable = Interactable.new({
        interact_func = function(self, e)
            if self.collides then
                -- open the door
                self.collides         = false
                self.renderable.glyph = "/"
                self.renderable.fg    = Colors.gray
            else
                -- close the door
                self.collides         = true
                self.renderable.glyph = "+"
                self.renderable.fg    = Colors.yellow
            end
        end,
    })

    obj.placement_rules = PlacementRules.new({
        valid_placement = function(x, y, map)
            if isCorridor(map, x, y) then
                return math.random(0, 99) < 25 -- 25% of the time
            end
        end
    })

    return obj
end

Registry.register("prefabs", "door", Door)

return Door