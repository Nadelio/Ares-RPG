local Registry = require("core.registry")

local Combat = {}


--TODO: implement an actual combat system
function Combat.attack(attacker, defender)

    local damage = attacker.unarmed_attack - defender.defense

    damage = math.max(1, damage)

    defender.current_hp = defender.current_hp - damage

    return damage
end

Registry.register("systems", "combat", Combat)

return Combat