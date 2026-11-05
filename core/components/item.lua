local Registry = require("core.registry")
local TableUtils = require("core.utils.table_utils")
local Item = {}

function Item.new(data)
    data = data or {}
    TableUtils.assert_data_only(data.triggers or {}, "item.triggers")

    local Renderable = Registry.resolve("components", "renderable")
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
        owner_id = data.owner_id,

        triggers = data.triggers or {},

        renderable = data.renderable or Renderable.new({ glyph = "?",  italics = italics })
    }
end

Registry.register("components", "item", Item)

return Item