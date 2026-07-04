local UI = require("core.systems.ui")

local UIRenderer = {}

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

function UIRenderer.build(context)
    return UI.build(context)
end

function UIRenderer.draw(widgets)
    local function draw_lines(lines, x, y)
        local fontHeight = love.graphics.getFont():getHeight() + 3

        for i, line in ipairs(lines) do
            local cursorX = x

            for _, segment in ipairs(line) do
                love.graphics.setColor(segment.color or {1,1,1})
                love.graphics.print(segment.text, cursorX, y + (i - 1) * fontHeight)

                cursorX = cursorX + love.graphics.getFont():getWidth(segment.text)
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