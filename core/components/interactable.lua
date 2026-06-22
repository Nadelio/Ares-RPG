local Interactable = {} 

function Interactable.new(interact_func)
    return {
        selected = false,
        interact = interact_func or function(self, e) end
    }
end

return Interactable