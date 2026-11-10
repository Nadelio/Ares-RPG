local Registry = require("core.registry")

local LootTable = {}

function LootTable.new(data)
    local Inventory = Registry.resolve("components", "inventory")
    return {
        inventory = data.inventory or Inventory.new({}),
        valid_items = data.valid_items or {}
    }
end

Registry.register("components", "loot_table", LootTable)
return LootTable