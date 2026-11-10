local ItemPrefab = require("core.utils.item_prefab")

return ItemPrefab.define("windbreaker", {
    name = "Windbreaker",
    description = "Thin armor for someone who plans on never getting hit twice.",
    rarity = "common",
    glyph = "[",
    bonuses = { defense = 1 },
})
