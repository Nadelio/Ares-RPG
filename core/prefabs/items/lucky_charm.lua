local ItemPrefab = require("core.utils.item_prefab")

return ItemPrefab.define("lucky_charm", {
    name = "Lucky Charm",
    description = "A trinket that seems to bend fortune slightly.",
    rarity = "uncommon",
    glyph = "*",
    bonuses = { luck = 1 },
})
