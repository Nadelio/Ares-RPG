local Registry = require("core.registry")

local UIState = {} 

function UIState.new(data)
    return {
        inventory_open = false,
        selected_slot = 1,
        selected_tile = { x = 2, y = 2, }, -- middle center
        chest_open = false,
        chest_target = nil,
        chest_selected_slot = 1,
        inventory_focus = "player",
        inventory_open_before_chest = false,
        level_up_open = false,
        level_up_tab = "stats",
        level_up_selected_index = 1,
    }
end

Registry.register("components", "ui_state", UIState)

return UIState 