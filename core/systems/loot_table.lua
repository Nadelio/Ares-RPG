local Registry = require("core.registry")

local LootTableSystem = {}

function LootTableSystem.init(Events, world, map, logger)
    Events.on("generate_loot_table", function(e)
        local container = e.container -- the container object we are generating the loot table for
        local valid_items = e.container.loot_table.valid_items -- the list of valid item prefabs

        local item_count = math.random(5)

        for i = 1, item_count, 1 do
            local item_to_add = valid_items[math.random(#valid_items)].new({})
            table.insert(container.loot_table.inventory.items, item_to_add)
        end
        
        logger:add("generate_loot_table", function(entry)
            return string.format(
                "[Action %d] Generated loot table for %s",
                entry.turn,
                entry.data.container.name
            )
        end, {
            container = container
        })
    end, 100)
end

Registry.register("systems", "loot_table", LootTableSystem)

return LootTableSystem