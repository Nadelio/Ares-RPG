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
    local query_array = {}
    for _, value in pairs(Registry[category]) do
        if filter_fn(value) then
            table.insert(query_array, value)
        end
    end

    return query_array
end

return Registry