local Registry = require("core.registry")
local TurnBuffer = Registry.resolve("systems", "turn_buffer")

local InputSystem = {}

function InputSystem.init(Events, world, map, logger)

    Events.on("input", function(e)

        local key = e.key
        local player = e.entity

        player.turn_buffer = player.turn_buffer or TurnBuffer.new()

        if key == "w" then
            player.turn_buffer:add({ type = "move", dx = 0, dy = -1 })

        elseif key == "s" then
            player.turn_buffer:add({ type = "move", dx = 0, dy = 1 })

        elseif key == "a" then
            player.turn_buffer:add({ type = "move", dx = -1, dy = 0 })

        elseif key == "d" then
            player.turn_buffer:add({ type = "move", dx = 1, dy = 0 })

        elseif key == "backspace" then
            player.turn_buffer:pop()

        elseif key == "i" then
            player.ui.inventory_open = not player.ui.inventory_open

        elseif key == "up" then
            if player.ui.inventory_open then
                player.ui.selected_slot = math.max(1, player.ui.selected_slot - 1)
            else
                player.ui.selected_tile.y = math.max(1, player.ui.selected_tile.y - 1)
            end
        elseif key == "right" then
            player.ui.selected_tile.x = math.min(3, player.ui.selected_tile.x + 1)
        elseif key == "left" then
            player.ui.selected_tile.x = math.max(1, player.ui.selected_tile.x - 1)
        elseif key == "down" then
            if player.ui.inventory_open then
                local item_count = player.inventory and #player.inventory.items or 0
                local max_slot = math.max(1, item_count)

                player.ui.selected_slot = math.min(max_slot, player.ui.selected_slot + 1)
            else
                player.ui.selected_tile.y = math.min(3, player.ui.selected_tile.y + 1)
            end
        elseif key == "e" then
            if player.ui.inventory_open then
                local item = player.inventory.items[player.ui.selected_slot]

                if not item then
                    return
                end

                if item.equipped then
                    Events.emit("inventory_unequip", {
                        entity = player,
                        index = player.ui.selected_slot,
                        item = item,
                        map = map
                    })
                else
                    Events.emit("inventory_equip", {
                        entity = player,
                        index = player.ui.selected_slot,
                        item = item,
                        map = map
                    })
                end
            else
                map:clear_selection() 
    
                local interactable = map:get_adjacent_interactable(player.position.x, player.position.y, player.ui.selected_tile.x, player.ui.selected_tile.y)
                if interactable then
                    interactable.interactable.selected = true
                    player.turn_buffer:add({
                        type = "interact",
                        tile = { x = player.ui.selected_tile.x, y = player.ui.selected_tile.y }
                    })
                end
            end

        elseif key == "q" then
            if player.ui.inventory_open then
                local item = player.inventory.items[player.ui.selected_slot]

                if item then
                    Events.emit("inventory_drop", {
                        entity = player,
                        index = player.ui.selected_slot,
                        item = item,
                        map = map
                    })
                end
            else --! THIS IS FOR DEBUGGING, PLEASE REMOVE BEFORE RELEASE
                player.turn_buffer:add({
                    type = "attack",
                    attacker = "{SYSTEM}",
                    target = player,
                    damage = 1
                })
            end

        elseif key == "return" then
            Events.emit("turn_commit", {
                entity = player,
                actions = player.turn_buffer:all(),
                map = map
            })

            player.turn_buffer:clear()
            map:clear_selection()

        end

        if key == "ctrl+z" then
            player.turn_buffer:clear()
            map:clear_selection()
        end

        Events.emit("preview_request", {
            entity = player,
            buffer = player.turn_buffer:all()
        })

    end, 100)

end

Registry.register("systems", "input", InputSystem)

return InputSystem