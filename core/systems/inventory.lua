local Registry = require("core.registry")
local StatSystem = require("core.systems.stats")
local Object = require("core.components.object")
local Interactable = require("core.components.interactable")
local Position = require("core.components.position")
local Inventory = require("core.components.inventory")

local InventorySystem = {}

local function ensure_inventory(entity)
    entity.inventory = entity.inventory or Inventory.new()
    entity.inventory.items = entity.inventory.items or {}

    return entity.inventory
end

local function get_item(entity, index)
    if not index then
        return nil
    end

    local inventory = ensure_inventory(entity)

    return inventory.items[index]
end

local function clamp_selected_slot(entity)
    if not entity.ui then
        return
    end

    local inventory = ensure_inventory(entity)
    local max_slot = math.max(1, #inventory.items)

    entity.ui.selected_slot = math.max(1, math.min(entity.ui.selected_slot or 1, max_slot))
end

function InventorySystem.init(Events, world, map, logger)

    Events.on("inventory_add", function(e)
        local entity = e.entity
        local item = e.item
        local inventory = ensure_inventory(entity)

        if entity.stats.current.capacity + item.size > StatSystem.get(entity.stats, "capacity") then
            Events.emit("inventory_remove", {
                entity = entity,
                index = #inventory.items
            })
        end
        
        table.insert(inventory.items, item)
        entity.stats.current.capacity = entity.stats.current.capacity + item.size
        clamp_selected_slot(entity)

    end, 100)

    Events.on("inventory_remove", function(e)
        local entity = e.entity
        local index = e.index
        local map = e.map
        local inventory = ensure_inventory(entity)
        local item = get_item(entity, index)

        if not item then
            return
        end

        if item.equipped then
            Events.emit("inventory_unequip", {
                entity = entity,
                index = index,
                item = item,
                map = map
            })
        end

        table.remove(inventory.items, index)

        entity.stats.current.capacity = entity.stats.current.capacity - item.size
        e.item = item
        clamp_selected_slot(entity)

    end, 100)

    Events.on("inventory_pickup", function(e)
        local entity = e.actor
        local item_obj = e.target
        local item = item_obj.item
        local map = e.map
        local inventory = ensure_inventory(entity)

        if entity.stats.current.capacity + item.size > StatSystem.get(entity.stats, "capacity") then
            Events.emit("inventory_drop", {
                entity = entity,
                index = #inventory.items,
                map = e.map
            })
        end
        
        item.dropped = false
        table.insert(inventory.items, item)
        entity.stats.current.capacity = entity.stats.current.capacity + item.size
        clamp_selected_slot(entity)
        map:remove_object(item_obj)
    end, 100)

    Events.on("inventory_drop", function(e)
        local entity = e.entity
        local index = e.index
        local map = e.map
        local inventory = ensure_inventory(entity)
        local item = get_item(entity, index)

        if not item then
            return
        end

        e.item = item

        if item.equipped then
            Events.emit("inventory_unequip", {
                entity = entity,
                index = index,
                item = item,
                map = map
            })
        end

        table.remove(inventory.items, index)
        entity.stats.current.capacity = entity.stats.current.capacity - item.size
        clamp_selected_slot(entity)

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
            item_obj.interactable = Interactable.new({
                interact_func = function(_, interact_event)
                    Events.emit("inventory_pickup", interact_event)
                end,
            })

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
        local item = e.item or get_item(entity, index)
        local map = e.map --? used for if items with carry capacity bonus are unequipped, so entity is forced to drop something (if capacity is overfilled)

        if not item then
            return
        end

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