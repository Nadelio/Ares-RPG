local Registry = require("core.registry")
local TableUtils = require("core.utils.table_utils")

local StatusEffect = {}

function StatusEffect.new(data)
    data = data or {}

    assert(type(data.id) == "string" and data.id ~= "", "Status effects require an id")
    TableUtils.assert_data_only(data.data or {}, "status_effect.data")

    return {
        id = data.id,
        name = data.name or data.id,
        duration = data.duration or 1,
        stacks = data.stacks or 1,
        max_stacks = data.max_stacks or 1,
        source_id = data.source_id,
        data = data.data or {},
    }
end

Registry.register("components", "status_effect", StatusEffect)

return StatusEffect
