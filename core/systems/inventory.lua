local Object = require("core.components.object")
local Interactable = require("core.components.interactable")
local Position = require("core.components.position")
local InventorySystem = {}

function InventorySystem.init(Events)

    Events.on("inventory_add", function(e) --! VOLATILE, WILL DELETE ITEMS IF OVER CARRY CAPACITY, USE "inventory_pickup" EVENT FOR NON-VOLATILE
        local entity = e.entity
        local item = e.item

        if entity.inventory.current_capacity + item.size > entity.inventory.total_capacity then
            Events.emit("inventory_remove", {
                entity = entity,
                index = #entity.inventory.items
            })
        end

        if not entity.inventory then
            entity.inventory = { items = {} }
        end
        
        table.insert(entity.inventory.items, item)
        entity.inventory.current_capacity = entity.inventory.current_capacity + item.size

    end, 100)

    Events.on("inventory_remove", function(e) --! VOLATILE, DELETES ITEMS
        local entity = e.entity
        local index = e.index

        if not entity.inventory or not entity.inventory.items[index] then
            return
        end

        local item = table.remove(entity.inventory.items, index)
        entity.inventory.current_capacity = entity.inventory.current_capacity - item.size

    end, 100)

    Events.on("inventory_pickup", function(e)
        local entity = e.actor
        local item_obj = e.target
        local item = item_obj.item
        local map = e.map

        if entity.inventory.current_capacity + item.size > entity.inventory.total_capacity then
            Events.emit("inventory_drop", {
                entity = entity,
                index = #entity.inventory.items,
                map = e.map
            })
        end

        if not entity.inventory then
            entity.inventory = { items = {} }
        end
        
        table.insert(entity.inventory.items, item)
        entity.inventory.current_capacity = entity.inventory.current_capacity + item.size
        map:remove_object(item_obj)
    end, 100)

    Events.on("inventory_drop", function(e)
        local entity = e.entity
        local index = e.index
        local map = e.map

        if not entity.inventory or not entity.inventory.items[index] then
            return
        end

        local item = table.remove(entity.inventory.items, index)
        entity.inventory.current_capacity = entity.inventory.current_capacity - item.size

        item.dropped = true
        if map then
            local item_obj = Object.new({
                name = item.name,
                type = "item",
                
                collides = false,
                position = Position.new(entity.position.x, entity.position.y),
                
                renderable = item.renderable,
            })

            item_obj.item = item
            item_obj.interactable = Interactable.new(function(entity, e)
                Events.emit("inventory_pickup", e)
            end)

            map:add_object(item_obj)
        end

    end, 100)

    Events.on("inventory_equip", function(e)
        local entity = e.entity
        local index = e.index
        local map = e.map --? used for if cursed item gets equipped that has negative carry capacity, so entity is forced to drop something (if capacity is overfilled)

        -- TODO: find way to programmatically go through all entries in the table and add them to the player stats (needs to be able to include homebrew stats)
    end, 100)

    Events.on("inventory_unequip", function(e)
        local entity = e.entity
        local index = e.index
        local map = e.map --? used for if items with carry capacity bonus are unequipped, so entity is forced to drop something (if capacity is overfilled)

        -- TODO: find way to programmatically go through all entries in the table and remove them to the player stats (needs to be able to include homebrew stats)
    end, 100)

end

return InventorySystem