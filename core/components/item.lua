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
        -- Game data
        name = data.name or "Unknown Item",
        description = data.description or "",
        rarity = data.rarity or "cursed",
        health = data.health or 0,
        attack = data.attack or 0,
        defense = data.defense or 0,
        movement = data.movement or 0,
        luck = data.luck or 0,
        capacity_bonus = data.capacity_bonus or 0,
        size = data.size or 1,
        equipped = false,
        dropped = data.dropped or false,

        -- Render data
        renderable = Renderable.new({ glyph = "?",  italics = italics })
    }
end

return Item