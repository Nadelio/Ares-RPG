local UI = require("core.render.ui")
local Colors = require("core.render.colors")

local UIRenderer = {}

function UIRenderer.build(player)

    local widgets = {}

    widgets.status = UI.status(player)

    if player.ui.inventory_open then
        widgets.inventory = UI.inventory(player)
    else
        widgets.inventory = UI.box("Inventory", 24, 1, {})
    end

    widgets.inventory_open = player.ui.inventory_open

    widgets.box = UI.box("Hello, World!", 24, 7, {
        {
            { text = " I'm a box!", color = Colors.reset }
        }
    })

    return widgets
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

    if widgets.status then
        draw_lines(widgets.status, 250, 10)
    end

    if widgets.inventory_open then
        draw_lines(widgets.inventory, 250, 110)
        draw_lines(widgets.box, 250, 230)
    else
        draw_lines(widgets.inventory, 250, 110)
        draw_lines(widgets.box, 250, 130)
    end

end

return UIRenderer