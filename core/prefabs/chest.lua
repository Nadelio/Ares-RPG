local Registry = require("core.registry")
local Events = require("core.events")

local Renderable = require("core.components.renderable")
local Position   = require("core.components.position")
local Interactable = require("core.components.interactable")
local LootTable = require("core.components.loot_table")
local Object = require("core.components.object")
local PlacementRules = require("core.components.placement_rules")

local UI = require("core.systems.ui")

local CoinItem = require("core.prefabs.coin")

local Chest = {}

local function clamp_chest_slot(player, chest)
    local items = chest and chest.loot_table.inventory and chest.loot_table.inventory.items or {}
    local max_slot = math.max(1, #items)

    player.ui.chest_selected_slot = math.max(1, math.min(player.ui.chest_selected_slot or 1, max_slot))
end

local function isWall(map, x, y)
    if x < 1 or y < 1 then return false end

    local row = map.tiles[y]
    if not row then return false end

    local tile = row[x]
    if not tile then return false end

    return tile.type == "W"
end

function Chest.new(data)
    local obj = Object.new({
        name = "Chest",
        type = "container",
        collides = true,
        position = Position.new({ x = (data.x or 0), y = (data.y or 0) }),

        renderable = Renderable.new({ glyph = "C" }),
    })

    obj.placement_rules = PlacementRules.new({
        valid_placement = function(x, y, map)
            if map.tiles[y][x].type ~= "X" then
                return false
            end

            local walls = {
                TL = isWall(map, x - 1, y - 1),
                TC = isWall(map, x    , y - 1),
                TR = isWall(map, x + 1, y - 1),
                ML = isWall(map, x - 1, y    ),
                MC = isWall(map, x    , y    ),
                MR = isWall(map, x + 1, y    ),
                BL = isWall(map, x - 1, y + 1),
                BC = isWall(map, x    , y + 1),
                BR = isWall(map, x + 1, y + 1),
            }
            
            local corners = {
                TL = walls.TL and walls.TC and walls.ML,
                TR = walls.TR and walls.TC and walls.MR,
                BL = walls.BL and walls.BC and walls.ML,
                BR = walls.BR and walls.BC and walls.MR
            }

            if corners.TL or corners.TR or corners.BL or corners.BR then
                if math.random(0, 100) < 10 then
                    return true
                end
            end
            return false
        end
    })
    obj.loot_table = LootTable.new({
        valid_items = {
            CoinItem
        }
    })
    obj.interactable = Interactable.new({
        interact_func = function(entity, e)
            local actor = e.actor

            if not actor or not actor.ui then
                return
            end

            if entity.first_open then -- generate loot table on the first time the chest is opened
                Events.emit("generate_loot_table", {
                    container = entity
                })
                entity.first_open = false
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
    obj.first_open = true

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
            and player.ui.chest_target.loot_table
            and player.ui.chest_target.loot_table.inventory
    end,
    build = function(context)
        local player = context.player
        local chest = player.ui.chest_target

        return UI.inventory_panel(
            chest.name or "Chest",
            chest.loot_table.inventory.items or {},
            player.ui.chest_selected_slot,
            {
                active = player.ui.inventory_focus == "chest",
                min_height = 7,
                width = 24,
            }
        )
    end
})

Registry.register("prefabs", "chest", Chest)

return Chest