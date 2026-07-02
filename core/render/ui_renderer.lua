local UI = require("core.systems.ui")

local UIRenderer = {}

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
        draw_lines(widget.lines, widget.x or 0, widget.y or 0)
    end

end

return UIRenderer