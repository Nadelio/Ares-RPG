local Registry = require("core.registry")

local Renderable = require("core.components.renderable")
local Position   = require("core.components.position")
local Interactable = require("core.components.interactable")
local Inventory = require("core.components.inventory")
local Object = require("core.components.object")
local UI = require("core.systems.ui")

local Chest = {}

local function clamp_chest_slot(player, chest)
    local items = chest and chest.inventory and chest.inventory.items or {}
    local max_slot = math.max(1, #items)

    player.ui.chest_selected_slot = math.max(1, math.min(player.ui.chest_selected_slot or 1, max_slot))
end

function Chest.new(data)
    local obj = Object.new({
        name = "Chest",
        type = "container",
        collides = true,
        position = Position.new({ x = (data.x or 0), y = (data.y or 0) }),

        renderable = Renderable.new({ glyph = "C" }),
    })

    obj.inventory = Inventory.new({
        items = data.items or {}
    })
    obj.interactable = Interactable.new({
        interact_func = function(entity, e)
            local actor = e.actor

            if not actor or not actor.ui then
                return
            end

            if actor.ui.chest_open and actor.ui.chest_target == entity then
                actor.ui.inventory_open = actor.ui.inventory_open_before_chest or false
                actor.ui.chest_open = false
                actor.ui.chest_target = nil
                actor.ui.chest_selected_slot = 1
                actor.ui.inventory_focus = "player"
                actor.ui.inventory_open_before_chest = false
                return
            end

            actor.ui.inventory_open_before_chest = actor.ui.inventory_open
            actor.ui.inventory_open = true
            actor.ui.chest_open = true
            actor.ui.chest_target = entity
            actor.ui.inventory_focus = "chest"
            clamp_chest_slot(actor, entity)
        end,
    })

    return obj 
end

-- create UI element
UI.register("chest_inventory", {
    order = 25,
    position = function(_, _, widgets)
        return UI.right_column_start_x(), UI.align_with(widgets, "inventory", UI.below(widgets, "status"))
    end,
    visible = function(context)
        local player = context.player

        return player
            and player.ui
            and player.ui.chest_open
            and player.ui.chest_target
            and player.ui.chest_target.inventory
    end,
    build = function(context)
        local player = context.player
        local chest = player.ui.chest_target

        return UI.inventory_panel(chest.name or "Chest", chest.inventory.items or {}, player.ui.chest_selected_slot, {
            active = player.ui.inventory_focus == "chest",
            min_height = 7,
            width = 24,
        })
    end,
})

Registry.register("prefabs", "chest", Chest)

return Chest