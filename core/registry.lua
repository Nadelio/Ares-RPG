local Registry = {}

Registry.components = {}
Registry.systems = {}
Registry.prefabs = {}

function Registry.register(category, name, value)
    if Registry[category][name] then
        error("Duplicate: " .. name)
    end

    Registry[category][name] = value
end

function Registry.overwrite(category, name, value)
    warn(category .. "." .. name .. " is being overwritten.")
    Registry[category][name] = value
end

function Registry.resolve(category, name)
    local value = Registry[category][name]

    assert(value, ("Missing registry entry: %s.%s"):format(category, name))

    return value
end

function Registry.query(category, filter_fn)
    -- TODO: implement a query function that collects an array of all of Registry[category] that matches the filter function
end

return Registry