local Registry = require("core.registry")
local Inventory = require("core.components.inventory")

local LootTable = {}

-- TODO: Implement a loot table system that fills the inventory with items marked as available in said loot table component on a specific event
function LootTable.new(data)
    return {
        inventory = data.inventory or Inventory.new({}),
        valid_items = data.valid_items or {}
    }
end

Registry.register("components", "loot_table", LootTable)
return LootTable