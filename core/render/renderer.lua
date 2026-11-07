local TileStyles = require("core.render.tile_styles")
local Colors = require("core.render.colors")
local RarityColors = require("core.render.raritycolors")
local Sprites = require("core.render.sprites")

local Renderer = {}

local object_map = {}
local entity_map = {}
local ghost_map = {}
local buffer = {}

local function build_tile_segment(x, y, map)
    local tile = map:get(x, y)

    if tile and TileStyles[tile.type] then
        local style = TileStyles[tile.type](x, y, map)

        -- Keep glyph-only tile styles supplied by mods working.
        if type(style) == "string" then
            style = { glyph = style }
        end

        return {
            text = style.glyph,
            fg = style.fg or Colors.reset,
            bg = style.bg,
            italics = style.italics,
            bold = style.bold,
            underline = style.underline,
            sprite = style.sprite
        }
    end

    return {
        text = " ",
        fg = Colors.reset
    }
end

function Renderer.build(world, map, preview, player_pos, cursor_direction)
    for k in pairs(object_map) do object_map[k] = nil end
    for k in pairs(entity_map) do entity_map[k] = nil end
    for k in pairs(ghost_map) do ghost_map[k] = nil end
    for i in ipairs(buffer) do buffer[i] = nil end

    local cursor_key = nil

    if cursor_direction then
        local dx = cursor_direction.x - 2
        local dy = cursor_direction.y - 2
        local x = player_pos.x + dx
        local y = player_pos.y + dy

        cursor_key = x .. "," .. y
    end

    for _, e in ipairs(world:get_all()) do
        if e.position and e.renderable then
            local key = e.position.x .. "," .. e.position.y
            entity_map[key] = e
        end
    end
    
    for _, objects in pairs(map.objects) do
        local obj = objects[#objects]

        if obj then
            object_map[obj.position.x .. "," .. obj.position.y] = obj
        end
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
            local segment = {}

            if entity then
                segment = {
                    text = entity.renderable.glyph,
                    fg = entity.renderable.fg,
                    bg = entity.renderable.bg,
                    italics = entity.renderable.italics,
                    bold = entity.renderable.bold,
                    underline = entity.renderable.underline,
                    invert = entity.interaction_selected,
                    sprite = entity.renderable.sprite,
                    --? sprite mode draws the map tile underneath the entity
                    under = build_tile_segment(x, y, map)
                }

            elseif ghost_map[key] then
                segment = {
                    text = ".",
                    fg = Colors.orange,
                    under = build_tile_segment(x, y, map)
                }

            elseif object_map[key] then
                local object = object_map[key]

                if object.interactable then
                    local render_color = object.renderable.fg

                    if object.item then
                        render_color = RarityColors[object.item.rarity]
                    end

                    segment = {
                        text = object.renderable.glyph,
                        fg = render_color,
                        bg = object.renderable.bg,
                        italics = object.renderable.italics,
                        bold = object.renderable.bold,
                        underline = object.renderable.underline,
                        invert = object.interactable.selected,
                        sprite = object.renderable.sprite,
                        under = build_tile_segment(x, y, map)
                    }
                else
                    segment = {
                        text = object.renderable.glyph,
                        fg = object.renderable.fg,
                        bg = object.renderable.bg,
                        italics = object.renderable.italics,
                        bold = object.renderable.bold,
                        underline = object.renderable.underline,
                        sprite = object.renderable.sprite,
                        under = build_tile_segment(x, y, map)
                    }
                end

            else
                segment = build_tile_segment(x, y, map)
            end

            if cursor_key and key == cursor_key then
                segment.invert = true
            end

            line[#line + 1] = segment
        end

        buffer[#buffer + 1] = line
    end

    return buffer
end

local function draw_cell(segment, x, y, cell)
    if segment.bg then
        love.graphics.setColor(segment.bg)
        love.graphics.rectangle("fill", x, y, cell, cell)
    end

    love.graphics.setColor(segment.fg or Colors.reset)
    Sprites.draw(segment.sprite or Sprites.DEFAULT_SPRITE, x, y, cell, cell)
end

local function draw_sprites(buffer, settings)
    local cell = settings.sprite_resolution or 16

    for row, line in ipairs(buffer) do
        local drawY = (row - 1) * cell

        for col, segment in ipairs(line) do
            local drawX = (col - 1) * cell

            if segment.under then
                --? Draw the map tile first so transparent pixels in the
                --? entity/object sprite show the map underneath.
                --? The overlaid sprite skips its own bg to not cover the tile.
                draw_cell(segment.under, drawX, drawY, cell)

                love.graphics.setColor(segment.fg or Colors.reset)
                Sprites.draw(segment.sprite or Sprites.DEFAULT_SPRITE, drawX, drawY, cell, cell)
            else
                draw_cell(segment, drawX, drawY, cell)
            end

            if segment.invert then
                love.graphics.setColor(Colors.cursor[1], Colors.cursor[2], Colors.cursor[3], 0.4)
                love.graphics.rectangle("fill", drawX, drawY, cell, cell)
            end
        end
    end

    love.graphics.setColor(1, 1, 1)
end

function Renderer.draw(buffer, settings)
    if settings and settings.sprite_rendering then
        draw_sprites(buffer, settings)
        return
    end

    local font = love.graphics.getFont()
    local lineHeight = font:getHeight()

    for row, line in ipairs(buffer) do
        local x = 0

        for _, segment in ipairs(line) do
            local fg = segment.fg or Colors.reset
            local bg = segment.bg --? if nil, don't draw a background

            local italics = segment.italics or false
            local bold = segment.bold or false
            local underline = segment.underline or false

            if segment.invert then
                fg = Colors.cursor
                bg = segment.fg
            end

            local drawY = (row - 1) * lineHeight
            local textWidth = font:getWidth(segment.text)

            if bg then
                love.graphics.setColor(bg)

                love.graphics.rectangle(
                    "fill",
                    x,
                    drawY,
                    textWidth,
                    lineHeight
                )
            end

            love.graphics.setColor(fg)

            if italics then
                love.graphics.push()

                love.graphics.translate(x, drawY)
                love.graphics.shear(-0.25, 0)

                if bold then
                    love.graphics.print(segment.text, 1, 0)
                end

                love.graphics.print(segment.text, 0, 0)

                love.graphics.pop()
            else
                if bold then
                    love.graphics.print(
                        segment.text,
                        x + 1,
                        drawY
                    )
                end

                love.graphics.print(
                    segment.text,
                    x,
                    drawY
                )
            end

            if underline then
                love.graphics.line(
                    x,
                    drawY + font:getHeight() - 1,
                    x + textWidth,
                    drawY + font:getHeight() - 1
                )
            end

            x = x + textWidth
        end
    end

    love.graphics.setColor(1,1,1)
end

return Renderer