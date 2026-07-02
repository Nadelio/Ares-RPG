local Registry = require("core.registry")
local RarityColors = require("core.render.raritycolors")
local Colors = require("core.render.colors")
local StatSystem = require("core.systems.stats")
local UI = {} 

UI.widgets = {}
UI.widget_order = {}
UI._next_widget_order = 0

local function normalize_context(context)
    if context and context.player then
        return context
    end

    return {
        player = context
    }
end

local function resolve_value(value, context, widget)
    if type(value) == "function" then
        return value(context, widget)
    end

    return value
end

local function is_list(value)
    return type(value) == "table" and value[1] ~= nil
end

function UI.register(id, widget)
    assert(type(id) == "string" and id ~= "", "UI widget id must be a non-empty string")
    assert(type(widget) == "table", ("UI widget '%s' must be a table"):format(id))
    assert(type(widget.build) == "function", ("UI widget '%s' must define build(context, UI)"):format(id))

    local existing = UI.widgets[id]

    if existing and existing._slot then
        widget._slot = existing._slot
    else
        UI._next_widget_order = UI._next_widget_order + 1
        widget._slot = UI._next_widget_order
        table.insert(UI.widget_order, id)
    end

    widget.id = id
    widget.order = widget.order or 0

    UI.widgets[id] = widget

    return widget
end

function UI.unregister(id)
    if not UI.widgets[id] then
        return
    end

    UI.widgets[id] = nil

    for i, widget_id in ipairs(UI.widget_order) do
        if widget_id == id then
            table.remove(UI.widget_order, i)
            break
        end
    end
end

function UI.clear_widgets()
    UI.widgets = {}
    UI.widget_order = {}
    UI._next_widget_order = 0
end

function UI.build_widget(id, context)
    context = normalize_context(context)

    local definition = UI.widgets[id]
    if not definition then
        return nil
    end

    local visible = definition.visible

    if visible ~= nil then
        visible = resolve_value(visible, context)

        if not visible then
            return nil
        end
    end

    local built = definition.build(context, UI)
    if not built then
        return nil
    end

    local widget

    if built.lines then
        widget = built
    elseif is_list(built) then
        widget = {
            lines = built
        }
    else
        return nil
    end

    widget.id = widget.id or id
    widget.order = widget.order or definition.order or 0
    widget.x = widget.x or resolve_value(definition.x, context, widget) or 0
    widget.y = widget.y or resolve_value(definition.y, context, widget) or 0

    return widget
end

function UI.build(context)
    context = normalize_context(context)

    local built_widgets = {}
    local ids = {}

    for _, id in ipairs(UI.widget_order) do
        if UI.widgets[id] then
            table.insert(ids, id)
        end
    end

    table.sort(ids, function(left_id, right_id)
        local left = UI.widgets[left_id]
        local right = UI.widgets[right_id]

        if left.order ~= right.order then
            return left.order < right.order
        end

        return left._slot < right._slot
    end)

    for _, id in ipairs(ids) do
        local widget = UI.build_widget(id, context)

        if widget and widget.lines then
            table.insert(built_widgets, widget)
        end
    end

    return built_widgets
end

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

function UI.inventory_panel(title, items, selected_slot, options)
    options = options or {}

    local content = {}
    local active = options.active or false
    local min_height = options.min_height or 7
    local width = options.width or 24
    local empty_text = options.empty_text or "(empty)"
    local display_title = active and (title .. " *") or title

    items = items or {}

    for i, item in ipairs(items) do
        local prefix = "  "

        if i == selected_slot then
            prefix = active and "> " or ": "
        end

        local color = RarityColors[item.rarity] or Colors.reset
        local name = item.name

        if item.equipped then
            name = "[" .. item.name .. "]"
        end

        table.insert(content, {
            { text = prefix, color = Colors.reset },
            { text = name, color = color }
        })
    end

    if #items == 0 then
        table.insert(content, {
            { text = empty_text, color = Colors.gray }
        })
    end

    return UI.box(
        display_title,
        width,
        math.max(#content, min_height),
        content
    )
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

function UI.inventory(player) -- easy wrapper for inventory_panel
    return UI.inventory_panel("Inventory", player.inventory.items or {}, player.ui.selected_slot, {
        active = not player.ui.chest_open or player.ui.inventory_focus == "player",
        min_height = 7,
        width = 24,
    })
end

UI.register("status", {
    order = 10,
    x = 250,
    y = 10,
    visible = function(context)
        return context.player and context.player.stats
    end,
    build = function(context)
        return UI.status(context.player)
    end,
})

UI.register("inventory", {
    order = 20,
    x = 250,
    y = 110,
    visible = function(context)
        return context.player and context.player.ui
    end,
    build = function(context)
        local player = context.player

        if player.ui.inventory_open then
            return UI.inventory(player)
        end

        return UI.box("Inventory", 24, 1, {})
    end,
})

UI.register("demo_box", {
    order = 30,
    x = 250,
    y = function(context)
        local player = context.player

        if player and player.ui and player.ui.inventory_open then
            return 230
        end

        return 130
    end,
    visible = function(context)
        return context.player ~= nil
    end,
    build = function(context)
        local player = context.player
        local content

        if player and player.ui and player.ui.chest_open then
            content = {
                {
                    { text = " LEFT/RIGHT focus", color = Colors.reset }
                },
                {
                    { text = " UP/DOWN   select", color = Colors.reset }
                },
                {
                    { text = " E         transfer", color = Colors.reset }
                },
                {
                    { text = " Q         close", color = Colors.reset }
                },
            }
        else
            content = {
                {
                    { text = " E inspect/interact", color = Colors.reset }
                },
                {
                    { text = " I inventory", color = Colors.reset }
                },
            }
        end

        return UI.box("Controls", 24, 7, content)
    end,
})

Registry.register("systems", "ui", UI)

return UI 