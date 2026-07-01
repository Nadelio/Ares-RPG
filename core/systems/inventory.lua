local Registry = require("core.registry")
local StatSystem = require("core.systems.stats")
local Object = require("core.components.object")
local Interactable = require("core.components.interactable")
local Position = require("core.components.position")
local Inventory = require("core.components.inventory")

local InventorySystem = {}

function InventorySystem.init(Events, world, map, logger)

    Events.on("inventory_add", function(e)
        local entity = e.entity
        local item = e.item

        if entity.stats.current.capacity + item.size > StatSystem.get(entity.stats, "capacity") then
            Events.emit("inventory_remove", {
                entity = entity,
                index = #entity.inventory.items
            })
        end

        if not entity.inventory then
            entity.inventory = Inventory.new()
        end
        
        table.insert(entity.inventory.items, item)
        entity.stats.current.capacity = entity.stats.current.capacity + item.size

    end, 100)

    Events.on("inventory_remove", function(e)
        local entity = e.entity
        local index = e.index
        local map = e.map

        if not entity.inventory or not entity.inventory.items[index] then
            entity.inventory = Inventory.new()
        end
        
        local item = table.remove(entity.inventory.items, index)

        if item.equipped then
            Events.emit("inventory_unequip", {
                entity = entity,
                index = index,
                map = map
            })
        end

        entity.stats.current.capacity = entity.stats.current.capacity - item.size

    end, 100)

    Events.on("inventory_pickup", function(e)
        local entity = e.actor
        local item_obj = e.target
        local item = item_obj.item
        local map = e.map

        if entity.stats.current.capacity + item.size > StatSystem.get(entity.stats, "capacity") then
            Events.emit("inventory_drop", {
                entity = entity,
                index = #entity.inventory.items,
                map = e.map
            })
        end

        if not entity.inventory then
            entity.inventory = Inventory.new()
        end
        
        table.insert(entity.inventory.items, item)
        entity.inventory.current.capacity = entity.inventory.current.capacity + item.size
        map:remove_object(item_obj)
    end, 100)

    Events.on("inventory_drop", function(e)
        local entity = e.entity
        local index = e.index
        local map = e.map

        --! [BUG] Dropping items on top of eachother deletes the first item(s)
        --! [BUG] Dropping the last item in your inventory makes the cursor disappear 
        --! [BUG] Dropping the last item in your inventory gives the logger gets a nil target (maybe increase logger event hook priorities?)

        if not entity.inventory or not entity.inventory.items[index] then
            entity.inventory = Inventory.new()
        end

        local item = table.remove(entity.inventory.items, index)
        entity.stats.current.capacity = entity.stats.current.capacity - item.size

        if item.equipped then
            Events.emit("inventory_unequip", {
                entity = entity,
                index = index,
                map = map
            })
        end

        item.dropped = true
        if map then
            local item_obj = Object.new({
                name = item.name,
                type = "item",
                
                collides = false,
                position = Position.new({
                    x = entity.position.x,
                    y = entity.position.y,
                }),
                
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
        local item = entity.inventory.items[index]
        local map = e.map --? used for if cursed item gets equipped that has negative carry capacity, so entity is forced to drop something (if capacity is overfilled)
        if item.equipped then
            return
        end

        item.equipped = true

        StatSystem.equip(entity.stats, item)

        table.insert(entity.stats.equipped_items, item)    
    end, 100)

    Events.on("inventory_unequip", function(e)
        local entity = e.entity
        local index = e.index
        local item = entity.inventory.items[index]
        local map = e.map --? used for if items with carry capacity bonus are unequipped, so entity is forced to drop something (if capacity is overfilled)

        if not item.equipped then
            return
        end

        item.equipped = false

        StatSystem.unequip(entity.stats, item)

        for i, equipped in ipairs(entity.stats.equipped_items) do
            if equipped == item then
                table.remove(entity.stats.equipped_items, i)
                break
            end
        end    
    end, 100)

end

Registry.register("systems", "inventory", InventorySystem)

return InventorySystem