local Registry = require("core.registry")
local TableUtils = require("core.utils.table_utils")

local ItemPrefab = {}

--? Defines and registers an item prefab from a data-only template.
--? The prefab's .new(data) merges overrides into the template, builds a
--? Renderable from `glyph` when one isn't supplied, and returns an Item.
function ItemPrefab.define(name, template)
    local prefab = {}

    function prefab.new(data)
        local Item = Registry.resolve("components", "item")
        local Renderable = Registry.resolve("components", "renderable")

        local merged = TableUtils.clone(template)

        for key, value in pairs(data or {}) do
            merged[key] = value
        end

        local glyph = merged.glyph
        merged.glyph = nil

        if not merged.renderable and glyph then
            merged.renderable = Renderable.new({ glyph = glyph })
        end

        return Item.new(merged)
    end

    Registry.register("prefabs", name, prefab)

    return prefab
end

return ItemPrefab
