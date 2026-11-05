local Registry = require("core.registry")

local Combat = {}

local function distance_between(attacker, defender)
    if not attacker or not attacker.position or not defender or not defender.position then
        return math.huge
    end

    return math.abs(attacker.position.x - defender.position.x)
        + math.abs(attacker.position.y - defender.position.y)
end

function Combat.can_attack(attacker, defender)
    if not attacker or not defender or attacker == defender then
        return false
    end

    if not attacker.stats or not defender.stats then
        return false
    end

    if attacker.dead or defender.dead then
        return false
    end

    if (attacker.stats.current.health or 0) <= 0 or (defender.stats.current.health or 0) <= 0 then
        return false
    end

    return distance_between(attacker, defender) == 1
end

function Combat.calculate_damage(attacker, defender)
    local StatSystem = Registry.resolve("systems", "stats")
    local attack = StatSystem.get(attacker.stats, "attack")
    local defense = StatSystem.get(defender.stats, "defense")

    return math.max(1, attack - defense)
end

function Combat.init(Events, world, map, logger)
    local ItemEffectSystem = Registry.resolve("systems", "item_effects")

    Events.on("attack", function(e)
        if not Combat.can_attack(e.attacker, e.target) then
            e.cancelled = true
            return
        end

        e.damage = Combat.calculate_damage(e.attacker, e.target)
    end, 200)

    Events.on("attack", function(e)
        if e.cancelled or (e.damage or 0) <= 0 then
            return
        end

        for _, item in ipairs(e.attacker.stats.equipped_items or {}) do
            ItemEffectSystem.trigger(Events, item, "on_hit", {
                item = item,
                owner = e.attacker,
                attacker = e.attacker,
                target = e.target,
                damage = e.damage,
                event = e,
            })
        end
    end, 50)
end

Registry.register("systems", "combat", Combat)

return Combat