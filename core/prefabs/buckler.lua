local ItemPrefab = require("core.utils.item_prefab")

return ItemPrefab.define("buckler", {
    name = "Buckler",
    description = "A small shield fit for one hand.",
    rarity = "common",
    glyph = "(",
    bonuses = { defense = 1 },
})
