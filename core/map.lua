local TableUtils = require("core.utils.table_utils")
local Map = {}
Map.__index = Map

function Map.new(tiles, objects)
    local self = setmetatable({}, Map)

    self.tiles = tiles or {
        {
            { type = "W" }, { type = "W" }, { type = "W" }
        },
        {
            { type = "W" }, { type = "X" }, { type = "W" }
        },
        {
            { type = "W" }, { type = "W" }, { type = "W" }
        }
    }

    self.objects = objects or {}

    return self
end

function Map:get(x, y)
    local row = self.tiles[y]
    if not row then return nil end

    local tile = row[x]
    if not tile then return nil end

    return tile
end

local function key_for(x, y)
    return x .. "," .. y
end

function Map:add_object(obj)
    local key = key_for(obj.position.x, obj.position.y)

    self.objects[key] = self.objects[key] or {}
    table.insert(self.objects[key], obj)
end

function Map:remove_object(obj)
    local key = key_for(obj.position.x, obj.position.y)
    local objects = self.objects[key]

    if not objects then
        return
    end

    for i = #objects, 1, -1 do
        if objects[i] == obj then
            table.remove(objects, i)
            break
        end
    end

    if #objects == 0 then
        self.objects[key] = nil
    end
end

function Map:get_objects(x, y)
    return self.objects[key_for(x, y)]
end

function Map:get_object(x, y)
    local objects = self:get_objects(x, y)

    if not objects then
        return nil
    end

    return objects[#objects]
end

function Map:get_interactable(x, y)
    local objects = self:get_objects(x, y)

    if not objects then
        return nil
    end

    for i = #objects, 1, -1 do
        local obj = objects[i]

        if obj and obj.interactable then
            return obj
        end
    end
end

function Map:get_adjacent_interactable(x, y, selected_tile_idx_x, selected_tile_idx_y)
    if not selected_tile_idx_x or not selected_tile_idx_y then
        return nil
    end

    local dx = selected_tile_idx_x - 2
    local dy = selected_tile_idx_y - 2

    return self:get_interactable(x + dx, y + dy)
end

function Map:clear_selection()
    for _, objects in pairs(self.objects) do
        for _, obj in ipairs(objects) do
            if obj.interactable then
                obj.interactable.selected = false
            end
        end
    end
end

return Map