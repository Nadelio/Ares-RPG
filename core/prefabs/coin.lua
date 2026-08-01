local Registry = require("core.registry")


local Coin = {}

function Coin.new(data)
    local Item = Registry.resolve("components", "item")
    local Renderable = Registry.resolve("components", "renderable")
    local c = Item.new({
        name = "Coin",
        description = "A gold coin",
        rarity = "coin",
        size = 1,
        renderable = Renderable.new({ glyph = "$" })
    })

    c.value = data.value
    return c
end

Registry.register("prefabs", "coin", Coin)
return Coin