local Registry = require("core.registry")

local Renderable = require("core.components.renderable")
local Position   = require("core.components.position")
local Interactable = require("core.components.interactable")
local Inventory = require("core.components.inventory")
local Object = require("core.components.object")

local Chest = {}

function Chest.new(x, y)
    local obj = Object.new({
        name = "Chest",
        type = "container",
        collides = true,
        position = Position.new(x, y),

        renderable = Renderable.new({ glyph = "C" }),
    })

    -- TODO: open up a new UI.box() that contains the chest's inventory
    obj.inventory = Inventory.new({ total_capacity = 10 }) 
    obj.interactable = Interactable.new(function(entity, e) print("You open the chest.") end)

    return obj 
end

Registry.register(Registry.prefabs, "chest", Chest)

return Chest