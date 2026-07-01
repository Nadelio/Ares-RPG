local Registry = require("core.registry")

local Renderable = require("core.components.renderable")
local Position   = require("core.components.position")
local Interactable = require("core.components.interactable")
local Inventory = require("core.components.inventory")
local Object = require("core.components.object")

local Chest = {}

function Chest.new(data)
    local obj = Object.new({
        name = "Chest",
        type = "container",
        collides = true,
        position = Position.new({ x = (data.x or 0), y = (data.y or 0) }),

        renderable = Renderable.new({ glyph = "C" }),
    })

    -- TODO: open up a new UI.box() that contains the chest's inventory
    obj.inventory = Inventory.new({ total_capacity = 10 }) 
    obj.interactable = Interactable.new({
        interact_func = function(entity, e)
            print("You open the chest.")
        end,
    })

    return obj 
end

Registry.register("prefabs", "chest", Chest)

return Chest