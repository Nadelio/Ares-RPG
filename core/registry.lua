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

function Registry.resolve(category, name)
    local value = Registry[category][name]

    assert(value, ("Missing registry entry: %s.%s"):format(category, name))

    return value
end

return Registry