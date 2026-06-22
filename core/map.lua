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

function Map:add_object(obj)
    self.objects[obj.position.x .. "," .. obj.position.y] = obj
    print("Added object: " .. obj.name .. "\n\tType: " .. obj.type)
    if obj.renderable then
        print(obj.name .. " has a renderable component\n\tGlyph: " .. obj.renderable.glyph)
    end
end

function Map:remove_object(obj)
    self.objects[obj.position.x .. "," .. obj.position.y] = nil
end

function Map:get_object(x, y)
    return self.objects[x .. "," .. y]
end

function Map:get_interactable(x, y)
    local obj = self:get_object(x, y)

    if obj and obj.interactable then
        return obj
    end
end

function Map:get_adjacent_interactable(x, y, selected_tile_idx_x, selected_tile_idx_y)
    if not selected_tile_idx_x or not selected_tile_idx_y then
        return nil
    end

    local dx = selected_tile_idx_x - 2
    local dy = selected_tile_idx_y - 2

    local obj = self:get_object(
            x + dx,
            y + dy
        )
    
    if obj and obj.interactable then
        return obj
    end

    return nil
end

function Map:clear_selection()
    for _, obj in pairs(self.objects) do
        if obj.interactable then
            obj.interactable.selected = false
        end
    end
end

return Map