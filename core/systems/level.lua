local Registry = require("core.registry")
local ClassSystem = require("core.systems.class")

local LevelSystem = {} 

local function is_integer(value)
    return type(value) == "number" and value % 1 == 0
end

LevelSystem.rewards = {
    move = 0.25,
    interact = 0.25,
    kill = 5,
    kill_advantage_bonus = 1,
    kill_disadvantage_bonus = 3,
    heal = 1,
    damage_taken = 1,
}

local function ensure_progression(entity)
    if not entity then
        return nil
    end

    entity.level = entity.level or 1
    entity.experience = entity.experience or 0
    entity.total_experience = entity.total_experience or 0
    entity.experience_to_next_level = entity.experience_to_next_level or (5 + entity.level)

    if entity.stats then
        entity.stats.base.level = entity.level
    end

    return entity
end

local function collect_enemy_tags(entity)
    local tags = {}

    if not entity then
        return tags
    end

    if type(entity.enemy_tag) == "string" and entity.enemy_tag ~= "" then
        table.insert(tags, entity.enemy_tag)
    end

    if type(entity.enemy_tags) == "table" then
        for _, tag in ipairs(entity.enemy_tags) do
            if type(tag) == "string" and tag ~= "" then
                table.insert(tags, tag)
            end
        end
    end

    if type(entity.tags) == "table" then
        for _, tag in ipairs(entity.tags) do
            if type(tag) == "string" and tag ~= "" then
                table.insert(tags, tag)
            end
        end
    end

    return tags
end

function LevelSystem.required_experience(entity, level)
    level = level or (entity and entity.level) or 1

    --? default exp curve keeps early levels close to 5 + level progression.
    return 5 + level
end

local function refresh_requirement(entity)
    entity.experience_to_next_level = LevelSystem.required_experience(entity, entity.level)
end

local function calculate_kill_experience(entity, target)
    local amount = LevelSystem.rewards.kill
    local enemy_tags = collect_enemy_tags(target)
    local has_advantage = false
    local has_disadvantage = false

    for _, tag in ipairs(enemy_tags) do
        if not has_advantage and ClassSystem.has_advantage(entity, tag) then
            has_advantage = true
        end

        if not has_disadvantage and ClassSystem.has_disadvantage(entity, tag) then
            has_disadvantage = true
        end
    end

    if has_advantage then
        amount = amount + LevelSystem.rewards.kill_advantage_bonus
    end

    if has_disadvantage then
        amount = amount + LevelSystem.rewards.kill_disadvantage_bonus
    end

    return amount
end

function LevelSystem.grant(Events, entity, amount, reason)
    if not entity or amount <= 0 then
        return 0
    end

    ensure_progression(entity)

    entity.experience = entity.experience + amount
    entity.total_experience = entity.total_experience + amount

    local levels_gained = 0
    local threshold = LevelSystem.required_experience(entity, entity.level + levels_gained)

    while entity.experience >= threshold do
        entity.experience = entity.experience - threshold
        levels_gained = levels_gained + 1
        threshold = LevelSystem.required_experience(entity, entity.level + levels_gained)
    end

    if levels_gained > 0 then
        Events.emit("level_up", {
            entity = entity,
            amount = levels_gained,
            reason = reason,
            previous_level = entity.level,
            new_level = entity.level + levels_gained,
            experience = entity.experience,
            total_experience = entity.total_experience,
        })
    end

    refresh_requirement(entity)

    return levels_gained
end

function LevelSystem.init(Events, world, map, logger)
    Events.on("experience_gain", function(e)
        local entity = ensure_progression(e.entity)
        local amount = e.amount or 0

        if e.cancelled or not entity or amount <= 0 then
            return
        end

        assert(type(amount) == "number", "Experience gains must be numeric")

        e.levels_gained = LevelSystem.grant(Events, entity, amount, e.reason)
    end, 100)

    Events.on("move", function(e)
        if e.cancelled or not e.entity then
            return
        end

        Events.emit("experience_gain", {
            entity = e.entity,
            amount = LevelSystem.rewards.move,
            reason = "move",
        })
    end, -50)

    Events.on("interact", function(e)
        if e.cancelled or not e.actor then
            return
        end

        Events.emit("experience_gain", {
            entity = e.actor,
            amount = LevelSystem.rewards.interact,
            reason = "interact",
        })
    end, -50)

    Events.on("attack", function(e)
        local entity = e.target or e.entity

        if e.cancelled or not entity or (e.damage or 0) <= 0 then
            return
        end

        Events.emit("experience_gain", {
            entity = entity,
            amount = LevelSystem.rewards.damage_taken,
            reason = "damage_taken",
        })
    end, -50)

    Events.on("heal", function(e)
        local entity = e.healer or e.actor or e.entity or e.target

        if e.cancelled or not entity or (e.amount or 0) <= 0 then
            return
        end

        Events.emit("experience_gain", {
            entity = entity,
            amount = LevelSystem.rewards.heal,
            reason = "heal",
        })
    end, -50)

    Events.on("death", function(e)
        local killer = e.killer or e.attacker
        local target = e.entity

        if e.cancelled or not killer or not target or killer == target then
            return
        end

        Events.emit("experience_gain", {
            entity = killer,
            amount = calculate_kill_experience(killer, target),
            reason = "kill",
        })
    end, -50)

    Events.on("level_up", function(e)
        local entity = ensure_progression(e.entity)
        local levels = e.amount or 1

        if not entity then
            e.cancelled = true
            return
        end

        assert(is_integer(levels), "Cannot add fractional levels")

        entity.level = entity.level + levels

        if entity.stats then
            entity.stats.base.level = entity.level
        end

        refresh_requirement(entity)

    end, 100) 

    for _, entity in ipairs(world:get_all()) do
        ensure_progression(entity)
        refresh_requirement(entity)
    end

end

Registry.register("systems", "level", LevelSystem)

return LevelSystem 