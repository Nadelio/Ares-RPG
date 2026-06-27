local StatSystem = {}

function StatSystem.get(stats, stat)
    local base = stats.base[stat] or 0
    local bonus = stats.bonuses[stat] or 0

    return base + bonus
end

local function modify(stats, bonuses, sign)
    for stat, amount in pairs(bonuses) do
        stats.bonuses[stat] =
            (stats.bonuses[stat] or 0) + amount * sign

        if stats.bonuses[stat] == 0 then
            stats.bonuses[stat] = nil
        end
    end
end

function StatSystem.equip(stats, item)
    modify(stats, item.bonuses, 1)
end

function StatSystem.unequip(stats, item)
    modify(stats, item.bonuses, -1)
end

function StatSystem.setBase(stats, stat, value)
    stats.base[stat] = value
end

function StatSystem.modifyBase(stats, stat, amount)
    stats.base[stat] = (stats.base[stat] or 0) + amount
end


return StatSystem