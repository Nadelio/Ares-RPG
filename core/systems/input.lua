local Registry = require("core.registry")
local TurnBuffer = require("core.systems.turn_buffer")
local StatSystem = require("core.systems.stats")
local ClassSystem = require("core.systems.class")

local InputSystem = {}

local function clamp_slot(index, item_count)
    local max_slot = math.max(1, item_count or 0)

    return math.max(1, math.min(index or 1, max_slot))
end

local function clamp_inventory_slots(player)
    local player_items = player.inventory and player.inventory.items or {}

    player.ui.selected_slot = clamp_slot(player.ui.selected_slot, #player_items)

    local chest = player.ui.chest_target
    local chest_items = chest and chest.inventory and chest.inventory.items or {}

    player.ui.chest_selected_slot = clamp_slot(player.ui.chest_selected_slot, #chest_items)
end

local function get_level_up_tabs(player)
    return ClassSystem.get_level_up_choices(player) or {}
end

local function has_pending_level_up_choices(player)
    local options = ClassSystem.get_level_up_options(player)

    if not options then
        return false
    end

    return options.pending_stat_choices > 0
        or options.pending_skill_choices > 0
        or options.pending_mastery_choices > 0
end

local function sync_level_up_menu(player)
    if not player or not player.ui then
        return nil, nil
    end

    local tabs = get_level_up_tabs(player)
    local active_index = 1

    if #tabs == 0 then
        player.ui.level_up_tab = "stats"
        player.ui.level_up_selected_index = 1
        return tabs, nil
    end

    for index, tab in ipairs(tabs) do
        if tab.id == player.ui.level_up_tab then
            active_index = index
            break
        end
    end

    local active_tab = tabs[active_index]

    if active_tab.pending <= 0 or (#active_tab.entries == 0 and #tabs > 1) then
        for index, tab in ipairs(tabs) do
            if tab.pending > 0 and #tab.entries > 0 then
                active_index = index
                active_tab = tab
                break
            end
        end
    end

    player.ui.level_up_tab = active_tab.id
    player.ui.level_up_selected_index = clamp_slot(player.ui.level_up_selected_index, #active_tab.entries)

    return tabs, active_index
end

local function close_level_up_ui(player)
    player.ui.level_up_open = false
    player.ui.level_up_selected_index = 1
end

local function open_level_up_ui(player)
    if not player or not player.ui then
        return false
    end

    if not has_pending_level_up_choices(player) then
        return false
    end

    player.ui.level_up_open = true
    sync_level_up_menu(player)

    return true
end

local function cycle_level_up_tab(player, direction)
    local tabs, active_index = sync_level_up_menu(player)

    if not tabs or #tabs == 0 then
        return
    end

    active_index = active_index or 1
    active_index = ((active_index - 1 + direction) % #tabs) + 1

    player.ui.level_up_tab = tabs[active_index].id
    player.ui.level_up_selected_index = clamp_slot(player.ui.level_up_selected_index, #tabs[active_index].entries)
end

local function handle_level_up_confirm(player, Events)
    local tabs = get_level_up_tabs(player)
    local active_tab

    for _, tab in ipairs(tabs) do
        if tab.id == player.ui.level_up_tab then
            active_tab = tab
            break
        end
    end

    if not active_tab then
        close_level_up_ui(player)
        return
    end

    local choice = active_tab.entries[player.ui.level_up_selected_index]

    if not choice then
        return
    end

    local payload = {
        entity = player,
    }

    if choice.kind == "stat" then
        payload.stat = choice.id
    elseif choice.kind == "skill" then
        payload.skill = choice.id
    elseif choice.kind == "spell" then
        payload.spell = choice.id
    elseif choice.kind == "mastery" then
        payload.mastery = choice.id
    end

    local result = Events.emit(choice.event, payload)

    if result.cancelled then
        return
    end

    if not has_pending_level_up_choices(player) then
        close_level_up_ui(player)
        return
    end

    sync_level_up_menu(player)
end

local function handle_level_up_input(player, key, Events)
    if key == "up" then
        local tabs = get_level_up_tabs(player)
        local active_tab

        for _, tab in ipairs(tabs) do
            if tab.id == player.ui.level_up_tab then
                active_tab = tab
                break
            end
        end

        if active_tab then
            player.ui.level_up_selected_index = math.max(1, player.ui.level_up_selected_index - 1)
            player.ui.level_up_selected_index = clamp_slot(player.ui.level_up_selected_index, #active_tab.entries)
        end
    elseif key == "down" then
        local tabs = get_level_up_tabs(player)
        local active_tab

        for _, tab in ipairs(tabs) do
            if tab.id == player.ui.level_up_tab then
                active_tab = tab
                break
            end
        end

        if active_tab then
            local max_slot = math.max(1, #active_tab.entries)
            player.ui.level_up_selected_index = math.min(max_slot, player.ui.level_up_selected_index + 1)
        end
    elseif key == "left" then
        cycle_level_up_tab(player, -1)
    elseif key == "right" then
        cycle_level_up_tab(player, 1)
    elseif key == "e" or key == "return" then
        handle_level_up_confirm(player, Events)
    elseif key == "q" or key == "l" then
        close_level_up_ui(player)
    end

    sync_level_up_menu(player)
end

local function close_chest_ui(player, keep_inventory_open)
    if keep_inventory_open == nil then
        player.ui.inventory_open = player.ui.inventory_open_before_chest or false
    else
        player.ui.inventory_open = keep_inventory_open
    end

    player.ui.chest_open = false
    player.ui.chest_target = nil
    player.ui.chest_selected_slot = 1
    player.ui.inventory_focus = "player"
    player.ui.inventory_open_before_chest = false
end

local function transfer_to_player(player, chest)
    local items = chest.inventory.items or {}
    local index = clamp_slot(player.ui.chest_selected_slot, #items)
    local item = items[index]

    if not item then
        return false
    end

    if player.stats.current.capacity + item.size > StatSystem.get(player.stats, "capacity") then
        return false
    end

    table.remove(items, index)
    table.insert(player.inventory.items, item)

    item.dropped = false
    player.stats.current.capacity = player.stats.current.capacity + item.size

    return true
end

local function transfer_to_chest(player, chest, Events, map)
    local items = player.inventory.items or {}
    local index = clamp_slot(player.ui.selected_slot, #items)
    local item = items[index]

    if not item then
        return false
    end

    if item.equipped then
        Events.emit("inventory_unequip", {
            entity = player,
            index = index,
            item = item,
            map = map
        })
    end

    table.remove(items, index)
    table.insert(chest.inventory.items, item)

    player.stats.current.capacity = player.stats.current.capacity - item.size

    return true
end

function InputSystem.init(Events, world, map, logger)
    Events.on("level_up", function(e)
        local player = e.entity

        if player and player.ui then
            open_level_up_ui(player)
        end
    end, 80)

    Events.on("input", function(e)

        local key = e.key
        local player = e.entity
        local chest_open = player.ui.chest_open and player.ui.chest_target and player.ui.chest_target.inventory

        player.turn_buffer = player.turn_buffer or TurnBuffer.new()

        if player.ui.level_up_open then
            handle_level_up_input(player, key, Events)
            Events.emit("preview_request", {
                entity = player,
                buffer = player.turn_buffer:all()
            })
            return
        end

        if key == "l" and open_level_up_ui(player) then
            Events.emit("preview_request", {
                entity = player,
                buffer = player.turn_buffer:all()
            })
            return
        end

        if key == "w" then
            if chest_open then
                close_chest_ui(player)
            end

            player.turn_buffer:add({ type = "move", dx = 0, dy = -1 })

        elseif key == "s" then
            if chest_open then
                close_chest_ui(player)
            end

            player.turn_buffer:add({ type = "move", dx = 0, dy = 1 })

        elseif key == "a" then
            if chest_open then
                close_chest_ui(player)
            end

            player.turn_buffer:add({ type = "move", dx = -1, dy = 0 })

        elseif key == "d" then
            if chest_open then
                close_chest_ui(player)
            end

            player.turn_buffer:add({ type = "move", dx = 1, dy = 0 })

        elseif key == "backspace" then
            player.turn_buffer:pop()

        elseif key == "i" then
            if chest_open then
                close_chest_ui(player, false)
            else
                player.ui.inventory_open = not player.ui.inventory_open
            end

        elseif key == "up" then
            if chest_open and player.ui.inventory_focus == "chest" then
                player.ui.chest_selected_slot = math.max(1, player.ui.chest_selected_slot - 1)
            elseif player.ui.inventory_open then
                player.ui.selected_slot = math.max(1, player.ui.selected_slot - 1)
            else
                player.ui.selected_tile.y = math.max(1, player.ui.selected_tile.y - 1)
            end
        elseif key == "right" then
            if chest_open then
                player.ui.inventory_focus = "chest"
            else
                player.ui.selected_tile.x = math.min(3, player.ui.selected_tile.x + 1)
            end
        elseif key == "left" then
            if chest_open then
                player.ui.inventory_focus = "player"
            else
                player.ui.selected_tile.x = math.max(1, player.ui.selected_tile.x - 1)
            end
        elseif key == "down" then
            if chest_open and player.ui.inventory_focus == "chest" then
                local item_count = #player.ui.chest_target.inventory.items
                player.ui.chest_selected_slot = math.min(math.max(1, item_count), player.ui.chest_selected_slot + 1)
            elseif player.ui.inventory_open then
                local item_count = player.inventory and #player.inventory.items or 0
                local max_slot = math.max(1, item_count)

                player.ui.selected_slot = math.min(max_slot, player.ui.selected_slot + 1)
            else
                player.ui.selected_tile.y = math.min(3, player.ui.selected_tile.y + 1)
            end
        elseif key == "e" then
            if chest_open then
                local chest = player.ui.chest_target
                local moved = false

                if player.ui.inventory_focus == "chest" then
                    moved = transfer_to_player(player, chest)
                else
                    moved = transfer_to_chest(player, chest, Events, map)
                end

                if moved then
                    clamp_inventory_slots(player)
                end

            elseif player.ui.inventory_open then
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
            if chest_open then
                close_chest_ui(player)
            elseif player.ui.inventory_open then
                local item = player.inventory.items[player.ui.selected_slot]

                if item then
                    Events.emit("inventory_drop", {
                        entity = player,
                        index = player.ui.selected_slot,
                        item = item,
                        map = map
                    })
                end
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

        clamp_inventory_slots(player)

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