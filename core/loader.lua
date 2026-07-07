local Registry = require("core.registry")

local Loader = {}
Loader.loaded_mods = {}

local function count_keys(tbl)
    local count = 0

    for _ in pairs(tbl) do
        count = count + 1
    end

    return count
end

local function require_category(category, directory)
    if not love.filesystem.getInfo(directory, "directory") then
        return {}
    end

    local items = love.filesystem.getDirectoryItems(directory)
    local loaded = {}

    table.sort(items)

    for _, item in ipairs(items) do
        if item:sub(-4) == ".lua" then
            local name = item:sub(1, -5)
            local module_path = directory:gsub("/", ".") .. "." .. name

            require(module_path)

            if not Registry[category][name] then
                error(("Module '%s' did not register itself in Registry.%s"):format(module_path, category))
            end

            table.insert(loaded, name)
        end
    end

    return loaded
end

local function load_manifest(mod_name, mod_root)
    local manifest_path = mod_root .. "/mod.lua"
    local manifest = { name = mod_name }

    if love.filesystem.getInfo(manifest_path, "file") then
        manifest = require(mod_root:gsub("/", ".") .. ".mod")
    end

    manifest.id = manifest.id or mod_name
    manifest.name = manifest.name or manifest.id
    manifest.description = manifest.description or ""
    manifest.dependencies = manifest.dependencies or {}
    manifest.root = mod_root

    assert(type(manifest.description) == "string", ("Mod '%s' description must be a string"):format(manifest.id))
    assert(type(manifest.dependencies) == "table", ("Mod '%s' dependencies must be a table"):format(manifest.id))

    for _, dependency in ipairs(manifest.dependencies) do
        assert(type(dependency) == "string", ("Mod '%s' dependency names must be strings"):format(manifest.id))
    end

    return manifest
end

local function register_alias(alias_to_id, alias, manifest)
    if not alias or alias == "" then
        return
    end

    local existing = alias_to_id[alias]

    if existing and existing ~= manifest.id then
        error(("Mod alias '%s' is ambiguous between '%s' and '%s'"):format(alias, existing, manifest.id))
    end

    alias_to_id[alias] = manifest.id
end

local function discover_mods(mods_root)
    local mods = love.filesystem.getDirectoryItems(mods_root)
    local mods_by_id = {}
    local alias_to_id = {}

    table.sort(mods)

    for _, mod_name in ipairs(mods) do
        local mod_root = mods_root .. "/" .. mod_name

        if love.filesystem.getInfo(mod_root, "directory") then
            local manifest = load_manifest(mod_name, mod_root)

            if mods_by_id[manifest.id] then
                error(("Duplicate mod id: %s"):format(manifest.id))
            end

            mods_by_id[manifest.id] = manifest
            register_alias(alias_to_id, manifest.id, manifest)
            register_alias(alias_to_id, mod_name, manifest)
            register_alias(alias_to_id, manifest.name, manifest)
        end
    end

    return mods_by_id, alias_to_id
end

local function order_mods(mods_by_id, alias_to_id)
    local incoming = {}
    local dependents = {}
    local ordered = {}

    for id in pairs(mods_by_id) do
        incoming[id] = 0
        dependents[id] = {}
    end

    for id, manifest in pairs(mods_by_id) do
        for _, dependency in ipairs(manifest.dependencies) do
            local dependency_id = alias_to_id[dependency] or dependency

            if not mods_by_id[dependency_id] then
                error(("Mod '%s' depends on missing mod '%s'"):format(id, dependency))
            end

            incoming[id] = incoming[id] + 1
            table.insert(dependents[dependency_id], id)
        end
    end

    local ready = {}

    for id, pending in pairs(incoming) do
        if pending == 0 then
            table.insert(ready, id)
        end
    end

    table.sort(ready)

    while #ready > 0 do
        local id = table.remove(ready, 1)
        local manifest = mods_by_id[id]

        table.insert(ordered, manifest)
        table.sort(dependents[id])

        for _, dependent in ipairs(dependents[id]) do
            incoming[dependent] = incoming[dependent] - 1

            if incoming[dependent] == 0 then
                table.insert(ready, dependent)
                table.sort(ready)
            end
        end
    end

    if #ordered ~= count_keys(mods_by_id) then
        local unresolved = {}

        for id, pending in pairs(incoming) do
            if pending > 0 then
                table.insert(unresolved, id)
            end
        end

        table.sort(unresolved)
        error(("Circular mod dependencies: %s"):format(table.concat(unresolved, ", ")))
    end

    return ordered
end

local function init_systems(system_names, events, world, map, logger)
    for _, name in ipairs(system_names) do
        local system = Registry.systems[name]

        if system and type(system.init) == "function" then
            system.init(events, world, map, logger)
        end
    end
end

function Loader.load_core_content()
    require_category("components", "core/components")
    require_category("systems", "core/systems")
    require_category("prefabs", "core/prefabs")
end

function Loader.load_mod_content(events, world, map, logger)
    local mods_root = "mods"

    --? In a fused exe, love.filesystem.mount cannot access the mods/ directory
    --? next to the .exe. Mods must go in the Love2D save directory instead,
    --? which is always in the search path automatically:
    --?   Windows: %APPDATA%\Roaming\AresRPG\mods\
    --?   MacOS:   ~/Library/Application Support/AresRPG/mods/
    --?   Linux:   ~/.local/share/AresRPG/mods/

    if not love.filesystem.getInfo(mods_root, "directory") then
        return {}
    end

    local loaded_mods = {}

    local mods_by_id, alias_to_id = discover_mods(mods_root)

    for _, manifest in ipairs(order_mods(mods_by_id, alias_to_id)) do
        if not Loader.loaded_mods[manifest.id] then
            require_category("components", manifest.root .. "/components")
            local mod_systems = require_category("systems", manifest.root .. "/systems")
            require_category("prefabs", manifest.root .. "/prefabs")
            init_systems(mod_systems, events, world, map, logger)

            if type(manifest.init) == "function" then
                manifest.init(events, world, map, logger)
            end

            Loader.loaded_mods[manifest.id] = manifest
            table.insert(loaded_mods, manifest)
        end
    end

    return loaded_mods
end

return Loader