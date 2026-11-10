local ItemPrefab = require("core.utils.item_prefab")

return ItemPrefab.define("field_coat", {
    name = "Field Coat",
    description = "A stitched coat with room for bandages and blame.",
    rarity = "common",
    glyph = "[",
    bonuses = { defense = 1, health = 1 },
})
