local Stats = {} 

local EntityStates = {
    DEAD = 0
}

function Stats.new(data)
    return {
        -- base stats
        health = data.health or 0,
        movement = data.movement or 0,
        luck = data.luck or 0,
        defense = data.defense or 0,
        unarmed_atk = data.unarmed_atk or 0,
        class = data.class or "None",
        homebrew = data.homebrew or {},

        -- game state
        level = data.level or 1,
        current_state = EntityStates.DEAD,
        items = {},
        equipped_items = {},

        current_hp = data.health,
        current_movement = 0,

        -- temp stat mods
        current_defense = data.defense,
        current_luck = data.luck,
        current_unarmed_atk = data.unarmed_atk,

        -- meta info
        name = data.name or "Unknown"
    } 
end

return Stats 