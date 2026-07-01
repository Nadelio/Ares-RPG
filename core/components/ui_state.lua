local Registry = require("core.registry")

local UIState = {} 

function UIState.new(data)
    return {
        inventory_open = false,
        selected_slot = 1,
        selected_tile = { x = 2, y = 2, } -- middle center
    }
end

Registry.register("components", "ui_state", UIState)

return UIState 