local Registry = require("core.registry")

local Interactable = {} 

function Interactable.new(data)
    return {
        selected = false,
        interact = data.interact_func or function(self, e) end
    }
end

Registry.register("components", "interactable", Interactable)

return Interactable