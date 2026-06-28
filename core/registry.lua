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

return Registry