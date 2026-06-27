local RarityColors = require("core.render.raritycolors") 
local Colors = require("core.render.colors")
local StatSystem = require("core.systems.stats")
local UI = {} 

function UI.box(title, width, height, content)
    width = math.max(1, width or 1)
    height = math.max(1, height or 1)
    content = content or {}

    if height == 1 then
        local titleText = title and (" " .. title .. " ") or ""
        local remaining = math.max(0, width - #titleText - 4)

        return {
            {
                {
                    text = "╶─" ..
                        titleText ..
                        string.rep("─", remaining) ..
                        "╴",
                    color = Colors.reset
                }
            }
        }
    end

    local innerWidth = math.max(0, width - 2)
    local innerHeight = math.max(0, height - 2)

    local lines = {}

    if title then
        local titleText = " " .. title .. " "
        local remaining = math.max(
            0,
            innerWidth - #titleText - 1
        )

        table.insert(lines, {
            {
                text = "╭─" ..
                    titleText ..
                    string.rep("─", remaining) ..
                    "╮",
                color = Colors.reset
            }
        })
    else
        table.insert(lines, {
            {
                text = "╭" ..
                    string.rep("─", innerWidth) ..
                    "╮",
                color = Colors.reset
            }
        })
    end

    local renderedRows = 0

    for i = 1, math.min(#content, innerHeight) do
        local row = content[i]

        local line = {
            { text = "│", color = Colors.reset }
        }

        local contentWidth = 0

        for _, segment in ipairs(row) do
            table.insert(line, segment)
            contentWidth = contentWidth + #segment.text
        end

        table.insert(line, {
            text = string.rep(
                " ",
                math.max(0, innerWidth - contentWidth)
            ),
            color = Colors.reset
        })

        table.insert(line, {
            text = "│",
            color = Colors.reset
        })

        table.insert(lines, line)

        renderedRows = renderedRows + 1
    end

    for _ = 1, innerHeight - renderedRows do
        table.insert(lines, {
            {
                text = "│" ..
                    string.rep(" ", innerWidth) ..
                    "│",
                color = Colors.reset
            }
        })
    end

    table.insert(lines, {
        {
            text = "╰" ..
                string.rep("─", innerWidth) ..
                "╯",
            color = Colors.reset
        }
    })

    return lines
end

function UI.status(player)
    local hp = player.stats.current.health
    local max_hp = StatSystem.get(player.stats, "health")
    local move = player.stats.current.movement
    local max_move = StatSystem.get(player.stats, "movement")
    local capacity = player.stats.current.capacity
    local max_capacity = StatSystem.get(player.stats, "capacity")

    local hpColor = Colors.green

    if hp / max_hp < 0.3 then
        hpColor = Colors.red
    elseif hp / max_hp < 0.6 then
        hpColor = Colors.yellow
    end

    local moveColor = Colors.green

    if move / max_move < 0.3 then
        moveColor = Colors.red
    elseif move / max_move < 0.6 then
        moveColor = Colors.yellow
    end

    local capacityColor = Colors.green

    if capacity / max_capacity < 0.3 then
        capacityColor = Colors.red
    elseif capacity / max_capacity < 0.6 then
        capacityColor = Colors.yellow
    end

    return UI.box("Status", 18, 6, {
        {
            { text = " HP       ", color = Colors.reset },
            { text = string.format("%2d/%2d", hp, max_hp), color = hpColor }
        },
        {
            { text = " MOVE     ", color = Colors.reset },
            { text = string.format("%2d/%2d", move, max_move), color = moveColor }
        },
        {
            { text = " CAPACITY ", color = Colors.reset },
            { text = string.format("%2d/%2d", capacity, max_capacity), color = capacityColor }
        },
        {
            { text = " LV       ", color = Colors.reset },
            { text = string.format("%2d", player.level), color = Colors.blue }
        }
    })
end

function UI.inventory(player)
    local content = {}

    local items = player.inventory.items or {}

    for i, item in ipairs(items) do
        local prefix = (i == player.ui.selected_slot) and ">" or " "
        local color = RarityColors[item.rarity] or Colors.reset
        local name = item.name

        if item.equipped then
            name = "["..item.name.."]"
        end

        table.insert(content, {
            { text = prefix .. " ", color = Colors.reset },
            { text = name, color = color }
        })
    end

    if #items == 0 then
        table.insert(content, {
            { text = "(empty)", color = Colors.gray }
        })
    end

    return UI.box(
        "Inventory",
        24,
        math.max(#content, 7),
        content
    )
end

return UI 