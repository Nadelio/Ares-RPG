local Registry = require("core.registry")
local Renderable = require("core.components.renderable")
local Item = {}

function Item.new(data)
    local italics = false
    if data.rarity then
        if data.rarity == "cursed" then
            italics = true
        end
    else
        italics = true
    end
    
    return {
        name = data.name or "Unknown Item",
        description = data.description or "",
        rarity = data.rarity or "cursed",

        bonuses = data.bonuses or {},

        size = data.size or 1,

        equipped = false,
        dropped = false,

        renderable = Renderable.new({ glyph = "?",  italics = italics })
    }
end



Registry.register("components", "item", Item)

return Item