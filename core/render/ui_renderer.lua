local UI = require("core.systems.ui")
local Sprites = require("core.render.sprites")
local Geometry = require("core.render.ui_geometry")

local UIRenderer = {}

local UTF8_CHAR = Geometry.UTF8_CHAR

--? Box-drawing glyphs that form widget borders. Sprite rendering mode does not
--? print these, the widget's sprite panel replaces them in the background layer.
UIRenderer.border_glyphs = Geometry.border_glyphs

local function panel_sprite(x, y)
    return {
        x = x,
        y = y,
        atlas_path = "./assets/textures/atlas_ui_16px.png",
        resolution = 16,
        rotation = 0
    }
end

--? Pieces of the sprite panel drawn behind bordered widgets in sprite
--? rendering mode. `corner` is the top-left corner and `edge` the left edge,
--? the other corners and edges reuse them rotated clockwise in 90 degree
--? steps, mirroring core.render.tile_styles. `fill` tiles the panel interior
--? and may be nil to let the widget's background show through instead.
--? `title_edge` is the left title cap (the right cap rotates 180 degrees);
--? `title_fill` tiles behind the title text, including its padding.
--? Mods may override entries or point them at their own atlas cells.
UIRenderer.panel_sprites = {
    corner = panel_sprite(1, 1),
    edge = panel_sprite(0, 1),
    fill = panel_sprite(1, 0),
    title_edge = panel_sprite(2, 0),
    title_fill = panel_sprite(2, 1),
}

local function measure_widget(widget)
    local width = 0
    local line_count = widget.lines and #widget.lines or 0
    local font = love.graphics.getFont()

    for _, line in ipairs(widget.lines or {}) do
        local text = ""

        for _, segment in ipairs(line) do
            text = text .. tostring(segment.text or "")
        end

        width = math.max(width, font:getWidth(text))
    end

    return width, line_count * (font:getHeight() + 3)
end

--? Draws a cols x rows grid of panel sprites, each one cell in size:
--? corners and edges around the outside, the optional fill inside.
--? Single-row/column panels degenerate into a plain edge strip.
local function draw_panel(x, y, cols, rows, cell, title_start, title_finish, title_rows)
    local corner = UIRenderer.panel_sprites.corner
    local edge = UIRenderer.panel_sprites.edge
    local fill = UIRenderer.panel_sprites.fill

    for row = 1, rows do
        for col = 1, cols do
            local sprite, rotation

            if rows == 1 then
                sprite, rotation = edge, 90
            elseif cols == 1 then
                sprite, rotation = edge, 0
            elseif row == 1 and col == 1 then
                sprite, rotation = corner, 0
            elseif row == 1 and col == cols then
                sprite, rotation = corner, 90
            elseif row == rows and col == cols then
                sprite, rotation = corner, 180
            elseif row == rows and col == 1 then
                sprite, rotation = corner, 270
            elseif row == 1 then
                sprite, rotation = edge, 90
            elseif col == cols then
                sprite, rotation = edge, 180
            elseif row == rows then
                sprite, rotation = edge, 270
            elseif col == 1 then
                sprite, rotation = edge, 0
            else
                sprite, rotation = fill, 0
            end

            if title_start and row <= title_rows then
                if col >= title_start and col <= title_finish then
                    sprite, rotation = UIRenderer.panel_sprites.title_fill, 0
                elseif col == title_start - 1 then
                    sprite, rotation = UIRenderer.panel_sprites.title_edge, 0
                elseif col == title_finish + 1 then
                    sprite, rotation = UIRenderer.panel_sprites.title_edge, 180
                end
            end

            if sprite then
                Sprites.draw(sprite, x + (col - 1) * cell, y + (row - 1) * cell, cell, cell, rotation)
            end
        end
    end
end

--? The widget's background rectangle, plus a sprite panel
--? sized in game cells for bordered widgets
local function draw_widget_background(widget, cell, size)
    local x = widget.x or 0
    local y = widget.y or 0
    if size.bordered then
        if widget.background then
            love.graphics.setColor(widget.background)
            love.graphics.rectangle("fill", x, y, size.width, size.height)
        end

        love.graphics.setColor(1, 1, 1)
        draw_panel(x, y, size.cols, size.rows, cell, size.title_start, size.title_finish, size.title_rows)
    elseif widget.background then
        love.graphics.setColor(widget.background)
        love.graphics.rectangle("fill", x, y, size.width, size.height)
    end
end

--? Icon sprites are drawn at the game cell size, border
--? glyphs are skipped (the panel replaced them), everything else stays text
local function draw_segment_foreground(segment, x, y, font, cell)
    local color = segment.color or {1, 1, 1}
    local text = tostring(segment.text or "")

    if segment.sprite then
        --? the segment's text is not printed, it only reserves layout space,
        --? so pad it to roughly the icon's width
        love.graphics.setColor(color)
        Sprites.draw(segment.sprite, x, y + (font:getHeight() - cell) / 2, cell, cell)

        return x + font:getWidth(text)
    end

    local cursorX = x
    local pending = {}
    local pendingX = x

    local function flush()
        if #pending > 0 then
            love.graphics.setColor(color)
            love.graphics.print(table.concat(pending), pendingX, y)

            for i = #pending, 1, -1 do pending[i] = nil end
        end
    end

    for char in text:gmatch(UTF8_CHAR) do
        if UIRenderer.border_glyphs[char] then
            flush()
        else
            if #pending == 0 then
                pendingX = cursorX
            end

            pending[#pending + 1] = char
        end

        cursorX = cursorX + font:getWidth(char)
    end

    flush()

    return cursorX
end

local function draw_sprite_mode(widgets, settings)
    local font = love.graphics.getFont()
    local fontHeight = font:getHeight()
    local cell = settings.sprite_resolution or 16
    local sizes = {}

    for index, widget in ipairs(widgets) do
        sizes[index] = Geometry.measure(widget, font, settings)
        draw_widget_background(widget, cell, sizes[index])
    end

    for index, widget in ipairs(widgets) do
        for i, line in ipairs(widget.lines or {}) do
            local cursorX = widget.x or 0
            local lineY = (widget.y or 0) + (i - 1) * fontHeight

            if i == 1 then
                cursorX = cursorX + sizes[index].title_offset
            elseif sizes[index].bordered then
                cursorX = cursorX + sizes[index].content_offset_x
                lineY = lineY + sizes[index].content_offset_y
            end

            for _, segment in ipairs(line) do
                cursorX = draw_segment_foreground(segment, cursorX, lineY, font, cell)
            end
        end
    end

    love.graphics.setColor(1, 1, 1)
end

function UIRenderer.build(context, settings)
    return UI.build(context, settings)
end

function UIRenderer.draw(widgets, settings)
    if settings and settings.sprite_rendering then
        draw_sprite_mode(widgets, settings)
        return
    end

    local function draw_lines(lines, x, y)
        local font = love.graphics.getFont()
        local fontHeight = font:getHeight()

        for i, line in ipairs(lines) do
            local cursorX = x
            local lineY = y + (i - 1) * fontHeight

            for _, segment in ipairs(line) do
                love.graphics.setColor(segment.color or {1,1,1})
                love.graphics.print(segment.text, cursorX, lineY)

                cursorX = cursorX + font:getWidth(segment.text)
            end
        end

        love.graphics.setColor(1,1,1)
    end

    for _, widget in ipairs(widgets) do
        if widget.background then
            local width, height = measure_widget(widget)

            love.graphics.setColor(widget.background)
            love.graphics.rectangle("fill", widget.x or 0, widget.y or 0, width, height)
        end

        draw_lines(widget.lines, widget.x or 0, widget.y or 0)
    end

end

return UIRenderer