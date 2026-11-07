local Geometry = {}

Geometry.UTF8_CHAR = "[%z\1-\127\194-\244][\128-\191]*"
Geometry.content_offset_y = 5
Geometry.border_glyphs = {
    ["│"] = true, ["─"] = true, ["╶"] = true, ["╴"] = true,
    ["╭"] = true, ["╮"] = true, ["╯"] = true, ["╰"] = true,
    ["├"] = true, ["┬"] = true, ["┤"] = true, ["┴"] = true,
    ["┼"] = true,
}

function Geometry.has_border(widget)
    for _, line in ipairs(widget.lines or {}) do
        for _, segment in ipairs(line) do
            for char in tostring(segment.text or ""):gmatch(Geometry.UTF8_CHAR) do
                if Geometry.border_glyphs[char] then
                    return true
                end
            end
        end
    end
    return false
end

local function measure_title(widget, font)
    local cursor = 0
    local start, finish
    local has_text, has_border = false, false
    for _, segment in ipairs((widget.lines or {})[1] or {}) do
        for char in tostring(segment.text or ""):gmatch(Geometry.UTF8_CHAR) do
            if Geometry.border_glyphs[char] then
                if start and has_text then
                    return start, finish
                end
                has_border = true
                start, finish = nil, nil
                has_text = false
            elseif has_border then
                start = start or cursor
                finish = cursor + font:getWidth(char)
                has_text = has_text or char:match("%S") ~= nil
            end
            cursor = cursor + font:getWidth(char)
        end
    end
end

function Geometry.measure(widget, font, settings)
    local lines = widget.lines or {}
    local width = 0
    for _, line in ipairs(lines) do
        local line_width = 0
        for _, segment in ipairs(line) do
            line_width = line_width + font:getWidth(tostring(segment.text or ""))
        end
        width = math.max(width, line_width)
    end

    local sprite_mode = settings and settings.sprite_rendering
    local size = {
        width = width,
        height = #lines * (font:getHeight() + (sprite_mode and 0 or 3)),
        bordered = sprite_mode and Geometry.has_border(widget) or false,
        title_offset = 0,
        content_offset_x = 0,
        content_offset_y = 0,
    }
    if not size.bordered then
        return size
    end

    local cell = settings.sprite_resolution or 16
    size.content_offset_x = math.max(font:getWidth("  "), cell)
    if #lines > 1 then
        size.content_offset_y = Geometry.content_offset_y
        size.height = size.height + size.content_offset_y
        size.width = size.width + size.content_offset_x + math.max(0, cell - font:getWidth("│"))
    end

    local start, finish = measure_title(widget, font)
    if start then
        size.title_offset = math.max(0, cell - start) + cell
        start, finish = start + size.title_offset, finish + size.title_offset
        size.width = math.max(size.width, finish + cell)
        size.title_start = math.floor(start / cell) + 1
        size.title_finish = math.ceil(finish / cell)
    end

    size.cols = math.max(1, math.ceil(size.width / cell))
    size.rows = math.max(1, math.ceil(size.height / cell))
    size.width, size.height = size.cols * cell, size.rows * cell
    size.title_rows = math.ceil(font:getHeight() / cell)
    return size
end

return Geometry
