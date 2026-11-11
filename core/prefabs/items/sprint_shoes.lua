local ItemPrefab = require("core.utils.item_prefab")

return ItemPrefab.define("sprint_shoes", {
    name = "Sprint Shoes",
    description = "Light shoes built for reckless route changes.",
    rarity = "rare",
    glyph = "[",
    bonuses = { movement = 1 },
})
