local ItemPrefab = require("core.utils.item_prefab")

return ItemPrefab.define("mouthguard", {
    name = "Mouthguard",
    description = "A battered guard that helps you keep your footing.",
    rarity = "common",
    glyph = "[",
    bonuses = { defense = 1 },
})
