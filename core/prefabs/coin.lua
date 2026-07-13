local Registry = require("core.registry")

local Item = require("core.components.item")
local Renderable = require("core.components.renderable")
local RarityColors = require("core.render.raritycolors")
local Colors = require("core.render.colors")

local Coin = {}

function Coin.new(data)
    local c = Item.new({
        name = "Coin",
        description = "A gold coin",
        rarity = RarityColors.common,
        size = 1,
        renderable = Renderable.new({ glyph = "$", fg = Colors.yellow })
    })

    c.value = data.value
    return c
end

Registry.register("prefabs", "coin", Coin)
return Coin