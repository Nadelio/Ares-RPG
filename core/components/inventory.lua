local Registry = require("core.registry")
local Item = require("core.components.item")
local RarityColors = require("core.render.raritycolors")
local Inventory = {}

function Inventory.new(data)
    local backpack = Item.new({
        name = "Backpack",
        description = "A sack used to carry items",
        rarity = RarityColors.common,
        bonuses = {
            capacity = 5
        }
    })

    backpack.items = data.items or {}

    return backpack
end

Registry.register("components", "inventory", Inventory)

return Inventory