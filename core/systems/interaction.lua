local Registry = require("core.registry")

local InteractionSystem = {}

local function tile_offset(tile)
    if not tile or not tile.x or not tile.y then
        return nil, nil
    end

    return tile.x - 2, tile.y - 2
end

local function entity_at(world, actor, x, y)
    for _, entity in ipairs(world:get_all()) do
        if entity ~= actor
            and entity.position
            and entity.position.x == x
            and entity.position.y == y
            and (entity.interactable or entity.stats)
        then
            return entity
        end
    end
end

function InteractionSystem.get_target(world, map, actor, tile)
    if not actor or not actor.position then
        return nil
    end

    local dx, dy = tile_offset(tile)

    if not dx or (dx == 0 and dy == 0) or math.abs(dx) > 1 or math.abs(dy) > 1 then
        return nil
    end

    local x = actor.position.x + dx
    local y = actor.position.y + dy
    local objects = map:get_objects(x, y) or {}

    for index = #objects, 1, -1 do
        local object = objects[index]

        if object.interactable or object.stats then
            return object
        end
    end

    return entity_at(world, actor, x, y)
end

function InteractionSystem.get_valid_interactions(target, event)
    local Interactable = Registry.resolve("components", "interactable")
    local Combat = Registry.resolve("systems", "combat")
    local interactions = Interactable.get_valid_interactions(target, event)
    local has_attack = false

    for _, interaction in ipairs(interactions) do
        if interaction.id == "attack" then
            has_attack = true
            break
        end
    end

    if not has_attack and Combat.can_attack(event.actor, target) then
        table.insert(interactions, {
            id = "attack",
            label = "Attack",
            description = "Attack this target.",
            action = function(defender, interaction_event)
                interaction_event.events.emit("attack", {
                    attacker = interaction_event.actor,
                    target = defender,
                })
            end,
        })
    end

    return interactions
end

function InteractionSystem.can_interact(target, event)
    return #InteractionSystem.get_valid_interactions(target, event) > 0
end

function InteractionSystem.clear_selection(world, map)
    map:clear_selection()

    for _, entity in ipairs(world:get_all()) do
        entity.interaction_selected = false
    end
end

function InteractionSystem.select(target)
    if not target then
        return
    end

    if target.interactable then
        target.interactable.selected = true
    else
        target.interaction_selected = true
    end
end

Registry.register("systems", "interaction", InteractionSystem)

return InteractionSystem
