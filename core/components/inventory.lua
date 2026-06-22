local Inventory = {} 

function Inventory.new(data)
    return {
        items = data.items or {},
        total_capacity = data.total_capacity or 5,
        current_capacity = data.current_capacity or 0
    } 
end

return Inventory 