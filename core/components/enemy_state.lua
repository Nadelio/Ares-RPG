local Registry = require("core.registry")

local EnemyState = {}

function EnemyState.new(data)
    return {}
end

Registry.register("components", "enemy_state", EnemyState)

return EnemyState