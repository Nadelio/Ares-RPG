local Registry = require("core.registry")

local Stats = {}

local EntityStates = {
    DEAD = 0
}

Stats.definitions = {
    { key = "health", label = "HP", current = true, current_mode = "remaining" },
    { key = "capacity", label = "LOAD", current = true, current_mode = "usage" },
    { key = "movement", label = "MOVE" },
    { key = "attack", label = "ATK" },
    { key = "defense", label = "DEF" },
    { key = "luck", label = "LCK" },
}

Stats.definition_map = {}

for _, definition in ipairs(Stats.definitions) do
    Stats.definition_map[definition.key] = definition
end

function Stats.get_definition(stat)
    return Stats.definition_map[stat]
end

function Stats.new(data)
    data = data or {}

    return {
        base = {
            health = data.health or 0,
            movement = data.movement or 0,
            luck = data.luck or 0,
            defense = data.defense or 0,
            attack = data.attack or data.unarmed_atk or 0,
            capacity = data.capacity or 1
        },

        bonuses = {},

        level = data.level or 1,
        current_state = EntityStates.DEAD,

        current = {
            health = data.health or 0,
            capacity = data.capacity or 0
        },

        equipped_items = {},

        class = data.class or "None",
        name = data.name or "Unknown"
    }
end

Registry.register("components", "stats", Stats)

return Stats