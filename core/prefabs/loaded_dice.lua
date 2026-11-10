local ItemPrefab = require("core.utils.item_prefab")

return ItemPrefab.define("loaded_dice", {
    name = "Loaded Dice",
    description = "Weighted just enough to offend a fair table.",
    rarity = "rare",
    glyph = "*",
    bonuses = { luck = 2 },
})
