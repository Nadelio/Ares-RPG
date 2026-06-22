local UIState = {} 

function UIState.new()
    return {
        inventory_open = false,
        selected_slot = 1,
        selected_tile = { x = 2, y = 2, } -- middle center
    } 
end

return UIState 