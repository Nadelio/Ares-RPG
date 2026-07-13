local Registry     = require("core.registry")
local Object       = require("core.components.object")
local Position     = require("core.components.position")
local Renderable   = require("core.components.renderable")
local Interactable = require("core.components.interactable")
local Colors       = require("core.render.colors")

local Door = {}

function Door.new(data)
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

    return obj
end

Registry.register("prefabs", "door", Door)

return Door