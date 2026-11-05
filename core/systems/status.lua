local Registry = require("core.registry")

local StatusSystem = {}

local function effects_for(entity)
    entity.status_effects = entity.status_effects or {}
    return entity.status_effects
end

local function find_effect(effects, id)
    for _, effect in ipairs(effects) do
        if effect.id == id then
            return effect
        end
    end
end

function StatusSystem.init(Events, world, map, logger)
    local StatusEffect = Registry.resolve("components", "status_effect")

    Events.on("status_apply", function(e)
        if not e.target or not e.effect then
            e.cancelled = true
            return
        end

        local incoming = StatusEffect.new(e.effect)
        incoming.source_id = incoming.source_id or (e.source and e.source.id)

        local effects = effects_for(e.target)
        local existing = find_effect(effects, incoming.id)

        if existing then
            existing.stacks = math.min(
                existing.max_stacks or 1,
                existing.stacks + incoming.stacks
            )
            existing.duration = math.max(existing.duration, incoming.duration)
            e.effect = existing
        else
            e.effect = incoming
            table.insert(effects, incoming)
        end

        Events.emit("status_applied", {
            target = e.target,
            source = e.source,
            effect = e.effect,
        })
    end, 100)

    Events.on("turn_end", function()
        for _, entity in ipairs(world:get_all()) do
            local effects = entity.status_effects or {}

            for index = #effects, 1, -1 do
                local effect = effects[index]

                Events.emit("status_turn", {
                    target = entity,
                    effect = effect,
                })

                effect.duration = effect.duration - 1

                if effect.duration <= 0 then
                    table.remove(effects, index)

                    Events.emit("status_removed", {
                        target = entity,
                        effect = effect,
                    })
                end
            end
        end
    end, 25)
end

Registry.register("systems", "status", StatusSystem)

return StatusSystem
