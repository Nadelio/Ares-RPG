local Registry = require("core.registry")

local Renderable = Registry.resolve("components", "renderable")
local Position   = Registry.resolve("components", "position")
local Interactable = Registry.resolve("components", "interactable")
local Inventory = Registry.resolve("components", "inventory")
local Object = Registry.resolve("components", "object")

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