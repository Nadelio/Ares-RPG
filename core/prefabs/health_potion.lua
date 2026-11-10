local ItemPrefab = require("core.utils.item_prefab")

return ItemPrefab.define("health_potion", {
    name = "Health Potion",
    description = "A small sweet potion.",
    rarity = "uncommon",
    glyph = "o",
    consumable = true,
    bonuses = { },
    triggers = {
        on_equip = {
            {
                event = "status_apply",

                data = {
                    effect = {
                        id = "regeneration",
                        name = "Regeneration",
                        duration = 2,
                        stacks = 1,
                        max_stacks = 5,

                        data = {
                            heal_amount = 1
                        }
                    }
                },

                bindings = {
                    source = "owner",
                    target = "entity",
                }
            }
        }
    }
})
