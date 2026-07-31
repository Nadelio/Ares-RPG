local Registry     = require("core.registry")
local MovementRules = require("core.systems.move_rules")

local BrainSystem = {}

local function astar(sx, sy, gx, gy, map, tile_scores, max_dist)
    if sx == gx and sy == gy then return {} end

    local function h(x, y)
        return math.abs(x - gx) + math.abs(y - gy)
    end

    local function nk(x, y) return x .. "," .. y end

    local open     = {}
    local node_map = {}  -- key -> node
    local closed   = {}
    local DIRS     = { {0,-1}, {0,1}, {-1,0}, {1,0} }
    local MAX_ITER = 400

    local start = { x = sx, y = sy, g = 0, f = h(sx, sy), parent = nil }
    node_map[nk(sx, sy)] = start
    table.insert(open, start)

    local iter = 0
    while #open > 0 and iter < MAX_ITER do
        iter = iter + 1

        local best_i = 1
        for i = 2, #open do
            if open[i].f < open[best_i].f then best_i = i end
        end
        local cur = table.remove(open, best_i)
        local cur_key = nk(cur.x, cur.y)

        if cur.x == gx and cur.y == gy then
            local path = {}
            local n = cur
            while n.parent do
                local p = node_map[n.parent]
                table.insert(path, 1, { dx = n.x - p.x, dy = n.y - p.y })
                n = p
            end
            return path
        end

        if not closed[cur_key] then
            closed[cur_key] = true

            for _, d in ipairs(DIRS) do
                local nx, ny = cur.x + d[1], cur.y + d[2]
                local key = nk(nx, ny)

                if not closed[key] then
                    local at_goal = nx == gx and ny == gy
                    local tile = map:get(nx, ny)
                    local passable = tile and tile.type ~= "W"
                        and (at_goal or MovementRules.can_move(map, nx, ny))

                    local in_range = (math.abs(nx - sx) + math.abs(ny - sy)) <= (max_dist or 32)

                    if passable and in_range then
                        local score = tile_scores[tile.type] or 1.0
                        local g = cur.g + (1.0 / math.max(score, 0.01))

                        local existing = node_map[key]
                        if not existing or g < existing.g then
                            local node = { x = nx, y = ny, g = g, f = g + h(nx, ny), parent = cur_key }
                            node_map[key] = node
                            table.insert(open, node)
                        end
                    end
                end
            end
        end
    end

    return nil
end

local function is_valid_target(brain, world, other)
    if other.dead or not other.position then return false end
    -- check if other is the player
    if other == world.player then
        for _, f in ipairs(brain.targets) do
            if f == "player" then return true end
        end
        return false
    end
    -- check faction
    if other.brain then
        for _, f in ipairs(brain.targets) do
            if f == other.brain.faction then return true end
        end
    end
    return false
end

local function entities_at(world, x, y)
    return world:query(function(e)
        return e.position and e.position.x == x and e.position.y == y
    end)
end

local function nearest_target(entity, brain, world)
    local best, best_dist = nil, math.huge
    for _, other in ipairs(world:get_all()) do
        if other ~= entity and is_valid_target(brain, world, other) then
            local dist = math.abs(other.position.x - entity.position.x)
                       + math.abs(other.position.y - entity.position.y)
            if dist <= brain.detect_range and dist < best_dist then
                best, best_dist = other, dist
            end
        end
    end
    return best
end

local function goal_attack_adjacent(entity, brain, world, map, Events)
    local DIRS = { {0,-1}, {0,1}, {-1,0}, {1,0} }
    local x, y = entity.position.x, entity.position.y
    for _, d in ipairs(DIRS) do
        for _, target in ipairs(entities_at(world, x + d[1], y + d[2])) do
            if is_valid_target(brain, world, target) then
                Events.emit("attack", {
                    attacker = entity,
                    target   = target,
                    damage   = entity.stats and entity.stats.base.attack or 1,
                })
                return true
            end
        end
    end
    return false
end

local function goal_chase(entity, brain, world, map, Events)
    local target = nearest_target(entity, brain, world)
    if not target then return false end

    local path = astar(
        entity.position.x, entity.position.y,
        target.position.x, target.position.y,
        map, brain.tile_scores, brain.detect_range * 2
    )

    if path and #path > 0 then
        Events.emit("move", { entity = entity, dx = path[1].dx, dy = path[1].dy })
        return true
    end
    return false
end

local function goal_wander(entity, brain, world, map, Events)
    local dirs = { {0,-1}, {0,1}, {-1,0}, {1,0} }
    for i = #dirs, 2, -1 do  -- Fisher-Yates shuffle
        local j = math.random(i)
        dirs[i], dirs[j] = dirs[j], dirs[i]
    end
    local x, y = entity.position.x, entity.position.y
    for _, d in ipairs(dirs) do
        if MovementRules.can_move(map, x + d[1], y + d[2]) then
            Events.emit("move", { entity = entity, dx = d[1], dy = d[2] })
            return true
        end
    end
    return false
end

local BUILTIN_GOALS = {
    attack_adjacent = goal_attack_adjacent,
    chase           = goal_chase,
    wander          = goal_wander,
}

local function run_brain(entity, world, map, Events)
    local brain = entity.brain

    -- copy and sort so the original goal list is never modified
    local sorted = {}
    for _, g in ipairs(brain.goals) do table.insert(sorted, g) end
    table.sort(sorted, function(a, b) return a.priority > b.priority end)

    for _, goal in ipairs(sorted) do
        local fn = goal.run or BUILTIN_GOALS[goal.type]
        if fn and fn(entity, brain, world, map, Events) then
            break
        end
    end
end

function BrainSystem.init(Events, world, map, logger)
    Events.on("turn_end", function(e)
        local npcs = world:query(function(entity)
            return entity.brain
                and entity.position
                and entity ~= world.player
                and not entity.dead
        end)
        for _, entity in ipairs(npcs) do
            run_brain(entity, world, map, Events)
        end
    end, 50)
end

Registry.register("systems", "brain", BrainSystem)

return BrainSystem