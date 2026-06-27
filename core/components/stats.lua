local Stats = {}

local EntityStates = {
    DEAD = 0
}

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
            movement = data.movement or 0,
            capacity = data.capacity or 0
        },

        equipped_items = {},

        class = data.class or "None",
        name = data.name or "Unknown"
    }
end

return Stats