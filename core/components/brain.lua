local Registry = require("core.registry")

local Brain = {}

-- Which factions each faction treats as hostile by default
Brain.DEFAULT_TARGETS = {
    hostile  = { "player", "friendly" },
    friendly = { "hostile" },
    neutral  = {},
}

-- Default goal lists per faction (run highest-priority first, stop on first success)
Brain.DEFAULT_GOALS = {
    hostile = {
        { priority = 100, type = "attack_adjacent" },
        { priority = 80,  type = "chase" },
        { priority = 10,  type = "wander" },
    },
    friendly = {
        { priority = 100, type = "attack_adjacent" },
        { priority = 80,  type = "chase" },
        { priority = 10,  type = "wander" },
    },
    neutral = {
        { priority = 10, type = "wander" },
    },
}

--- Creates a brain component.
--- @param data.faction   string  `"hostile"` | `"friendly"` | `"neutral"` (default is `"neutral"`)
--- @param data.goals     table   list of `{priority, type}` or `{priority, run=fn}`, defaults chosen by faction
--- @param data.tile_scores table  tile_type -> preference weight (default is `1.0`, higher = preferred)
--- @param data.detect_range number  manhattan-distance sight radius (default is `8`)
--- @param data.targets   table   list of faction strings this entity will target, overrides defaults
function Brain.new(data)
    data = data or {}
    local faction = data.faction or "neutral"
    return {
        faction      = faction,
        goals        = data.goals or Brain.DEFAULT_GOALS[faction] or { { priority = 10, type = "wander" } },
        tile_scores  = data.tile_scores or {},
        detect_range = data.detect_range or 8,
        targets      = data.targets or Brain.DEFAULT_TARGETS[faction] or {},
    }
end

Registry.register("components", "brain", Brain)

return Brain