local ItemPrefab = require("core.utils.item_prefab")

return ItemPrefab.define("weighted_wraps", {
    name = "Weighted Wraps",
    description = "Cloth wraps packed with enough heft to sting.",
    rarity = "common",
    glyph = ")",
    bonuses = { attack = 2 },
})
