local ItemPrefab = require("core.utils.item_prefab")

return ItemPrefab.define("bone_saw", {
    name = "Bone Saw",
    description = "Sharp enough for surgery and emergencies alike.",
    rarity = "common",
    glyph = ")",
    bonuses = { attack = 1 },
})
