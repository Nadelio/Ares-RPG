local Events = {} 

Events._listeners = {} 
Events._priorities = {} 

function Events.on(eventType, fn, priority)
    priority = priority or 0 

    Events._listeners[eventType] = Events._listeners[eventType] or {} 

    table.insert(Events._listeners[eventType], {
        fn = fn,
        priority = priority
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

    for _, listener in ipairs(listeners) do

        listener.fn(data) 

        if data.cancelled then
            break 
        end
    end

    return data 
end

function Events.before(eventType, fn)
    Events.on("before:" .. eventType, fn, 200) 
end

function Events.after(eventType, fn)
    Events.on("after:" .. eventType, fn, -200) 
end

return Events 