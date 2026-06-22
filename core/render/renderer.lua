local TileStyles = require("core.render.tile_styles")
local Colors = require("core.render.colors")
local RarityColors = require("core.render.raritycolors")

local Renderer = {}

local object_map = {}
local entity_map = {}
local ghost_map = {}
local buffer = {}

function Renderer.build(world, map, preview)
    for k in pairs(object_map) do object_map[k] = nil end
    for k in pairs(entity_map) do entity_map[k] = nil end
    for k in pairs(ghost_map) do ghost_map[k] = nil end
    for i in ipairs(buffer) do buffer[i] = nil end

    for _, e in ipairs(world:get_all()) do
        if e.position and e.renderable then
            local key = e.position.x .. "," .. e.position.y
            entity_map[key] = e
        end
    end
    
    for _, obj in pairs(map.objects) do
        object_map[obj.position.x .. "," .. obj.position.y] = obj
    end
    
    if preview then
        for _, step in ipairs(preview) do
            if step.x and step.y then
                local key = step.x .. "," .. step.y
                ghost_map[key] = true
            end
        end
    end

    for y, row in ipairs(map.tiles) do
        local line = {}

        for x = 1, #row do
            local key = x .. "," .. y
            local entity = entity_map[key]

            if entity then
                line[#line + 1] = {
                    text = entity.renderable.glyph,
                    color = Colors.green
                }

            elseif ghost_map[key] then
                line[#line + 1] = {
                    text = ".",
                    color = Colors.yellow
                }

            elseif object_map[key] then
                local object = object_map[key]

                if object.interactable and object.interactable.selected then
                    line[#line + 1] = {
                        text = object.renderable.glyph,
                        color = Colors.blue
                    }
                elseif object.interactable then
                    local render_color = Colors.reset
                    if object.item then
                        render_color = RarityColors[object.item.rarity]
                    end

                    line[#line + 1] = {
                        text = object.renderable.glyph,
                        color = render_color
                    }
                else
                    line[#line + 1] = {
                        text = object.renderable.glyph,
                        color = Colors.reset
                    }
                end

            else
                local tile = map:get(x, y)

                if tile and TileStyles[tile.type] then
                    line[#line + 1] = {
                        text = TileStyles[tile.type](x, y, map),
                        color = Colors.reset
                    }
                else
                    line[#line + 1] = {
                        text = " ",
                        color = Colors.reset
                    }
                end
            end
        end

        buffer[#buffer + 1] = line
    end

    return buffer
end

function Renderer.draw(buffer)
    local font = love.graphics.getFont()
    local lineHeight = font:getHeight() + 3

    for row, line in ipairs(buffer) do
        local x = 0

        for _, segment in ipairs(line) do
            love.graphics.setColor(segment.color or {1,1,1})

            love.graphics.print(
                segment.text,
                x,
                (row - 1) * lineHeight
            )

            x = x + font:getWidth(segment.text)
        end
    end

    love.graphics.setColor(1,1,1)
end

return Renderer