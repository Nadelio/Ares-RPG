local Registry = require("core.registry")

local ItemEffectSystem = {}

local function clone(value, seen)
    if type(value) ~= "table" then
        return value
    end

    seen = seen or {}

    if seen[value] then
        return seen[value]
    end

    local copy = {}
    seen[value] = copy

    for key, entry in pairs(value) do
        copy[clone(key, seen)] = clone(entry, seen)
    end

    return copy
end

local function build_payload(descriptor, context)
    local payload = clone(descriptor.data or {})

    payload.item = context.item

    for payload_key, context_key in pairs(descriptor.bindings or {}) do
        payload[payload_key] = context[context_key]
    end

    return payload
end

function ItemEffectSystem.trigger(Events, item, trigger_name, context)
    if not item then
        return nil
    end

    local descriptors = item.triggers and item.triggers[trigger_name] or {}
    local last_result

    for _, descriptor in ipairs(descriptors) do
        assert(
            type(descriptor.event) == "string" and descriptor.event ~= "",
            ("Item trigger '%s' requires an event name"):format(trigger_name)
        )

        context = context or {}
        context.item = item
        last_result = Events.emit(descriptor.event, build_payload(descriptor, context))

        if last_result.cancelled then
            return last_result
        end
    end

    return last_result
end

Registry.register("systems", "item_effects", ItemEffectSystem)

return ItemEffectSystem
