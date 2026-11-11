local ItemPrefab = require("core.utils.item_prefab")

return ItemPrefab.define("dagger", {
    name = "Dagger",
    description = "A short blade that is easy to tuck away.",
    rarity = "common",
    glyph = ")",
    bonuses = { attack = 1 },
})
