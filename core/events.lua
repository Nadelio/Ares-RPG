local Events = {} 

Events._listeners = {} 
Events._priorities = {} 

function Events.on(eventType, fn, priority)
    priority = priority or 0

    Events._listeners[eventType] = Events._listeners[eventType] or {}

    table.insert(Events._listeners[eventType], {
        fn = fn,
        priority = priority,
        expires = false
    })

    table.sort(Events._listeners[eventType], function(a, b)
        return a.priority > b.priority
    end)
end

function Events.emit(eventType, data)
    local listeners = Events._listeners[eventType]
    if not listeners then return data end

    data = data or {}

    data.cancelled = false

    for idx, listener in ipairs(listeners) do

        listener.fn(data)

        if listener.expires and listener.times <= 0 then
            table.remove(listeners, idx)
        elseif listener.expires and listener.times > 0 then
            listener.times = listener.times - 1
        end

        if data.cancelled then
            break
        end
    end

    return data
end

--- listen to an event once before removing from listeners
function Events.once(eventType, fn, priority)
    priority = priority or 0

    Events._listeners[eventType] = Events._listeners[eventType] or {}

    table.insert(Events._listeners[eventType], {
        fn = fn,
        priority = priority,
        expires = true,
        times = 1
    })

    table.sort(Events._listeners[eventType], function(a, b)
        return a.priority > b.priority
    end)
end

--- listen to an event `times` times before removing from listeners
function Events.only(eventType, fn, priority, times)
    priority = priority or 0

    Events._listeners[eventType] = Events._listeners[eventType] or {}

    table.insert(Events._listeners[eventType], {
        fn = fn,
        priority = priority,
        expires = true,
        times = times
    })

    table.sort(Events._listeners[eventType], function(a, b)
        return a.priority > b.priority
    end)
end

function Events.before(eventType, fn)
    Events.on("before:" .. eventType, fn, math.maxinteger)
end

function Events.after(eventType, fn)
    Events.on("after:" .. eventType, fn, -math.maxinteger)
end

return Events