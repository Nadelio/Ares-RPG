local Registry = require("core.registry")
local Stats = require("core.components.stats")
local RarityColors = require("core.render.raritycolors")
local Colors = require("core.render.colors")
local StatSystem = require("core.systems.stats")
local ClassSystem = require("core.systems.class")
local UI = {}

UI.widgets = {}
UI.widget_order = {}
UI._next_widget_order = 0
UI.layout = {
    margin = 5,
    gutter = 5,
    row_gap = 5,
    right_column_width = 32,
}

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

local function title_case(text)
    local words = {}

    for part in tostring(text):gmatch("[^_]+") do
        table.insert(words, part:sub(1, 1):upper() .. part:sub(2):lower())
    end

    return table.concat(words, " ")
end

local function get_stat_definition(stat)
    return Stats.get_definition(stat) or {
        key = stat,
        label = title_case(stat)
    }
end

local function format_bonus(amount)
    if amount >= 0 then
        return "+" .. tostring(amount)
    end

    return tostring(amount)
end

local function get_ratio_color(current, maximum, mode)
    if maximum <= 0 then
        return Colors.reset
    end

    local ratio = current / maximum

    if mode == "usage" then
        if ratio >= 0.85 then
            return Colors.red
        elseif ratio >= 0.6 then
            return Colors.yellow
        end

        return Colors.green
    end

    if ratio < 0.3 then
        return Colors.red
    elseif ratio < 0.6 then
        return Colors.yellow
    end

    return Colors.green
end

local function wrap_text(text, width)
    local lines = {}
    local normalized = tostring(text or "")

    if normalized == "" then
        return { "" }
    end

    for paragraph in normalized:gmatch("[^\n]+") do
        local current = ""

        for word in paragraph:gmatch("%S+") do
            local candidate = current == "" and word or (current .. " " .. word)

            if #candidate <= width then
                current = candidate
            else
                if current ~= "" then
                    table.insert(lines, current)
                end

                if #word <= width then
                    current = word
                else
                    local start_index = 1

                    while start_index <= #word do
                        table.insert(lines, word:sub(start_index, start_index + width - 1))
                        start_index = start_index + width
                    end

                    current = ""
                end
            end
        end

        if current ~= "" then
            table.insert(lines, current)
        end
    end

    if #lines == 0 then
        table.insert(lines, "")
    end

    return lines
end

local function get_font()
    if love and love.graphics and love.graphics.getFont then
        return love.graphics.getFont()
    end

    return nil
end

local function get_screen_size()
    if love and love.graphics and love.graphics.getDimensions then
        return love.graphics.getDimensions()
    end

    return 800, 600
end

local function get_line_height()
    local font = get_font()

    if font then
        return font:getHeight() + 3
    end

    return 19
end

local function measure_text_width(text)
    local normalized = tostring(text or "")
    local font = get_font()

    if font then
        return font:getWidth(normalized)
    end

    return #normalized * 8
end

local function measure_widget(widget)
    local width = 0
    local line_count = widget.lines and #widget.lines or 0

    for _, row in ipairs(widget.lines or {}) do
        local row_width = 0

        for _, segment in ipairs(row) do
            row_width = row_width + measure_text_width(segment.text)
        end

        width = math.max(width, row_width)
    end

    return {
        width = width,
        height = line_count * get_line_height(),
    }
end

local function find_widget(widgets, id)
    for _, widget in ipairs(widgets or {}) do
        if widget.id == id then
            return widget
        end
    end

    return nil
end

local function measure_box_width(width)
    return measure_text_width(string.rep(" ", math.max(0, width or 0)))
end

local function measure_row_text_width(row)
    local width = 0

    for _, segment in ipairs(row or {}) do
        width = width + #tostring(segment.text or "")
    end

    return width
end

local function measure_content_text_width(content)
    local width = 0

    for _, row in ipairs(content or {}) do
        width = math.max(width, measure_row_text_width(row))
    end

    return width
end

function UI.top_y(offset)
    return UI.layout.margin + (offset or 0)
end

function UI.left_column_x(widget)
    local screen_width = get_screen_size()
    local widget_width = measure_widget(widget).width
    local reserved_width = measure_box_width(UI.layout.right_column_width)

    return math.max(
        UI.layout.margin,
        screen_width - UI.layout.margin - reserved_width - UI.layout.gutter - widget_width
    )
end

function UI.right_column_x(widget)
    local screen_width = get_screen_size()
    local widget_width = measure_widget(widget).width

    return math.max(UI.layout.margin, screen_width - UI.layout.margin - widget_width)
end

function UI.right_column_start_x()
    local screen_width = get_screen_size()
    local reserved_width = measure_box_width(UI.layout.right_column_width)

    return math.max(UI.layout.margin, screen_width - UI.layout.margin - reserved_width)
end

function UI.align_with(widgets, id, fallback)
    local target = find_widget(widgets, id)

    if target and target.y then
        return target.y
    end

    return fallback or UI.top_y()
end

function UI.below(widgets, id, spacing)
    local target = find_widget(widgets, id)

    if not target then
        return UI.top_y()
    end

    return (target.y or UI.top_y()) + measure_widget(target).height + (spacing or UI.layout.row_gap)
end

local function get_ordered_bonus_keys(bonuses)
    local ordered = {}
    local seen = {}

    for _, definition in ipairs(Stats.definitions) do
        if bonuses[definition.key] ~= nil then
            table.insert(ordered, definition.key)
            seen[definition.key] = true
        end
    end

    local extras = {}

    for stat in pairs(bonuses) do
        if not seen[stat] then
            table.insert(extras, stat)
        end
    end

    table.sort(extras)

    for _, stat in ipairs(extras) do
        table.insert(ordered, stat)
    end

    return ordered
end

local function selected_inventory_item(player)
    if not player or not player.ui then
        return nil, nil
    end

    if player.ui.chest_open and player.ui.chest_target and player.ui.inventory_focus == "chest" then
        local chest = player.ui.chest_target
        local chest_items = chest.inventory and chest.inventory.items or {}

        return chest_items[player.ui.chest_selected_slot], chest.name or "Chest Item"
    end

    if player.ui.inventory_open and player.inventory and player.inventory.items then
        return player.inventory.items[player.ui.selected_slot], "Item Details"
    end

    return nil, nil
end

local function build_status_rows(player)
    local rows = {}
    local compact_entries = {}
    table.insert(rows, {
        { text = string.format(" %-8s", "CLASS"), color = Colors.reset },
        { text = string.format(" %-8s", player.stats.class), color = Colors.blue }
    })
    table.insert(rows, {
        { text = string.format(" %-8s", "XP"), color = Colors.reset },
        { text = string.format("%4.2f/%4.2f", player.experience or 0, player.experience_to_next_level or (5 + (player.level or 1))), color = Colors.blue }
    })
    for _, definition in ipairs(Stats.definitions) do
        local total = StatSystem.get(player.stats, definition.key)

        if definition.current then
            local current = player.stats.current[definition.key] or 0
            local color = get_ratio_color(current, total, definition.current_mode)

            table.insert(rows, {
                { text = string.format(" %-8s", definition.label), color = Colors.reset },
                { text = string.format("%2d/%2d", current, total), color = color }
            })
        else
            table.insert(compact_entries, {
                label = definition.label,
                value = tostring(total),
                color = total > 0 and Colors.blue or Colors.reset
            })
        end
    end

    for i = 1, #compact_entries, 2 do
        local left = compact_entries[i]
        local right = compact_entries[i + 1]
        local row = {
            { text = string.format(" %-4s", left.label), color = Colors.reset },
            { text = string.format("%3s", left.value), color = left.color }
        }

        if right then
            table.insert(row, { text = "  ", color = Colors.reset })
            table.insert(row, { text = string.format("%-4s", right.label), color = Colors.reset })
            table.insert(row, { text = string.format("%3s", right.value), color = right.color })
        end

        table.insert(rows, row)
    end

    return rows
end

local function build_item_detail_rows(item)
    if not item then
        return {
            {
                { text = " Select an item to inspect", color = Colors.gray }
            }
        }
    end

    local content = {}
    local rarity_color = RarityColors[item.rarity] or Colors.reset
    local rarity = title_case(item.rarity or "unknown")
    local description = item.description

    if description == "" then
        description = "No description"
    end

    table.insert(content, {
        { text = item.name or "Unknown Item", color = rarity_color }
    })
    table.insert(content, {
        { text = " RARITY ", color = Colors.reset },
        { text = rarity, color = rarity_color }
    })
    table.insert(content, {
        { text = " SIZE    ", color = Colors.reset },
        { text = tostring(item.size or 0), color = Colors.blue }
    })

    if item.equipped then
        table.insert(content, {
            { text = " Equipped", color = Colors.green }
        })
    end

    table.insert(content, {
        { text = " DESC", color = Colors.reset }
    })

    for _, line in ipairs(wrap_text(description, 30)) do
        table.insert(content, {
            { text = " " .. line, color = Colors.gray }
        })
    end

    table.insert(content, {
        { text = " BONUSES", color = Colors.reset }
    })

    local bonus_keys = get_ordered_bonus_keys(item.bonuses or {})

    if #bonus_keys == 0 then
        table.insert(content, {
            { text = " none", color = Colors.gray }
        })
    else
        for _, stat in ipairs(bonus_keys) do
            local definition = get_stat_definition(stat)

            table.insert(content, {
                { text = string.format(" %-8s", definition.label), color = Colors.reset },
                { text = format_bonus(item.bonuses[stat]), color = Colors.blue }
            })
        end
    end

    return content
end

local function find_level_up_tab(player, tabs)
    for _, tab in ipairs(tabs or {}) do
        if tab.id == player.ui.level_up_tab then
            return tab
        end
    end

    return tabs and tabs[1] or nil
end

local function append_level_up_detail_rows(rows, entry, player)
    if not entry then
        return
    end

    table.insert(rows, {
        { text = " DETAILS", color = Colors.reset }
    })

    if entry.kind == "stat" then
        local current = StatSystem.get(player.stats, entry.id)

        table.insert(rows, {
            { text = string.format(" %s %d -> %d", entry.label, current, current + 1), color = Colors.blue }
        })
    else
        table.insert(rows, {
            { text = string.format(" %s [%s]", entry.label or entry.name or "Unknown", string.upper(entry.kind or "skill")), color = Colors.blue }
        })

        for _, line in ipairs(wrap_text(entry.description or "No description", 42)) do
            table.insert(rows, {
                { text = " " .. line, color = Colors.gray }
            })
        end

        if entry.cost and next(entry.cost) ~= nil then
            table.insert(rows, {
                { text = " COST", color = Colors.reset }
            })

            for _, stat in ipairs(get_ordered_bonus_keys(entry.cost)) do
                local definition = get_stat_definition(stat)

                table.insert(rows, {
                    { text = string.format(" %-8s", definition.label), color = Colors.reset },
                    { text = format_bonus(entry.cost[stat]), color = Colors.red }
                })
            end
        end

        if entry.bonuses and next(entry.bonuses) ~= nil then
            table.insert(rows, {
                { text = " BONUSES", color = Colors.reset }
            })

            for _, stat in ipairs(get_ordered_bonus_keys(entry.bonuses)) do
                local definition = get_stat_definition(stat)

                table.insert(rows, {
                    { text = string.format(" %-8s", definition.label), color = Colors.reset },
                    { text = format_bonus(entry.bonuses[stat]), color = Colors.green }
                })
            end
        end
    end

    table.insert(rows, {
        { text = " E/ENTER choose  Q close", color = Colors.gray },
        { text = " LEFT/RIGHT switch tabs", color = Colors.gray }
    })
end

local function build_level_up_rows(player)
    local rows = {}
    local tabs = ClassSystem.get_level_up_choices(player) or {}
    local active_tab = find_level_up_tab(player, tabs)

    table.insert(rows, {
        { text = string.format(" Level %d reached", player.level or 1), color = Colors.green }
    })

    if #tabs == 0 then
        table.insert(rows, {
            { text = " No rewards available right now", color = Colors.gray }
        })
        table.insert(rows, {
            { text = " Q close", color = Colors.gray },
            { text = " LEFT/RIGHT switch tabs", color = Colors.gray }
        })
        return rows
    end

    for _, tab in ipairs(tabs) do
        local label = string.format(" %s [%d] ", tab.label, tab.pending)
        local color = tab.id == player.ui.level_up_tab and Colors.cursor or Colors.reset

        table.insert(rows, {
            { text = label, color = color }
        })
    end

    table.insert(rows, {
        { text = " OPTIONS", color = Colors.reset }
    })

    if active_tab and #active_tab.entries > 0 then
        for index, entry in ipairs(active_tab.entries) do
            local prefix = index == player.ui.level_up_selected_index and "> " or "  "
            local label = entry.label or entry.name or entry.id or "Unknown"
            local suffix = ""

            if entry.kind == "stat" then
                suffix = " +1"
            else
                suffix = " [" .. string.upper(entry.kind or "skill") .. "]"
            end

            table.insert(rows, {
                { text = prefix, color = index == player.ui.level_up_selected_index and Colors.cursor or Colors.reset },
                { text = label, color = index == player.ui.level_up_selected_index and Colors.cursor or Colors.reset },
                { text = suffix, color = Colors.gray }
            })
        end
    else
        table.insert(rows, {
            { text = " No choices in this tab yet", color = Colors.gray }
        })
    end

    if active_tab then
        append_level_up_detail_rows(rows, active_tab.entries[player.ui.level_up_selected_index], player)
    end

    return rows
end

local function build_mod_rows(mods)
    local content = {}
    local title_width = 30

    if not mods or #mods == 0 then
        table.insert(content, {
            { text = " No mods loaded", color = Colors.gray }
        })

        return content
    end

    for _, manifest in ipairs(mods) do
        local version_text = " v" .. (manifest.version or "0.0.0")
        local name = manifest.name or manifest.id or "Unknown Mod"
        local wrapped_name = wrap_text(name, math.max(1, title_width - #version_text))

        table.insert(content, {
            { text = wrapped_name[1], color = Colors.blue },
            { text = version_text, color = Colors.gray }
        })

        for i = 2, #wrapped_name do
            table.insert(content, {
                { text = wrapped_name[i], color = Colors.blue }
            })
        end

        for _, line in ipairs(wrap_text(manifest.description or "No description", 28)) do
            table.insert(content, {
                { text = " " .. line, color = Colors.gray }
            })
        end
    end

    return content
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
        local definition = UI.widgets[id]
        local widget = UI.build_widget(id, context)

        if widget and widget.lines then
            if definition.position then
                local x, y = definition.position(context, widget, built_widgets)

                if x ~= nil then
                    widget.x = x
                end

                if y ~= nil then
                    widget.y = y
                end
            end

            table.insert(built_widgets, widget)
        end
    end

    return built_widgets
end

function UI.box(title, width, height, content, options)
    content = content or {}
    options = options or {}

    local min_width = math.max(1, width or 1)
    local min_height = math.max(1, height or 1)
    local title_width = 0

    if title then
        title_width = #(" " .. title .. " ") + 3
    end

    width = math.max(min_width, measure_content_text_width(content) + 2, title_width)

    if min_height == 1 then
        height = 1
        width = math.max(width, title and (#(" " .. title .. " ") + 4) or 4)
    else
        height = math.max(min_height, #content + 2)
    end

    if height == 1 then
        local titleText = title and (" " .. title .. " ") or ""
        local remaining = math.max(0, width - #titleText - 4)

        local lines = {
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

        if options.background then
            return {
                lines = lines,
                background = options.background,
            }
        end

        return lines
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

    if options.background then
        return {
            lines = lines,
            background = options.background,
        }
    end

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
    local rows = build_status_rows(player)

    return UI.box("Status", 24, #rows + 2, rows)
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
    position = function(_, widget)
        return UI.left_column_x(widget), UI.top_y()
    end,
    visible = function(context)
        return context.player and context.player.stats
    end,
    build = function(context)
        return UI.status(context.player)
    end,
})

UI.register("inventory", {
    order = 20,
    position = function(_, widget, widgets)
        return UI.left_column_x(widget), UI.below(widgets, "status")
    end,
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

UI.register("item_details", {
    order = 26,
    position = function(context, widget, widgets)
        local player = context.player

        if player and player.ui and player.ui.chest_open then
            return UI.right_column_x(widget), UI.below(widgets, "chest_inventory")
        end

        return UI.right_column_x(widget), UI.align_with(widgets, "inventory", UI.below(widgets, "status"))
    end,
    visible = function(context)
        local player = context.player

        return player
            and player.ui
            and (player.ui.inventory_open or player.ui.chest_open)
    end,
    build = function(context)
        local player = context.player
        local item, title = selected_inventory_item(player)
        local rows = build_item_detail_rows(item)

        return UI.box("Item Details", 32, math.max(#rows + 2, 9), rows)
    end,
})

UI.register("mods", {
    order = 23,
    position = function(_, widget, widgets)
        return UI.right_column_x(widget), UI.align_with(widgets, "inventory", UI.below(widgets, "status"))
    end,
    visible = function(context)
        local player = context.player

        return context.mods
            and #context.mods > 0
            and player
            and player.ui
            and not player.ui.inventory_open
            and not player.ui.chest_open
    end,
    build = function(context)
        local rows = build_mod_rows(context.mods)

        return UI.box("Mods", 32, math.max(#rows + 2, 7), rows)
    end,
})

UI.register("level_up", {
    order = 100,
    position = function(_, widget)
        local screen_width, screen_height = get_screen_size()
        local size = measure_widget(widget)

        return math.floor((screen_width - size.width) / 2), math.floor((screen_height - size.height) / 2)
    end,
    visible = function(context)
        local player = context.player

        return player
            and player.ui
            and player.ui.level_up_open
    end,
    build = function(context)
        local player = context.player
        local rows = build_level_up_rows(player)

        return UI.box("Level Up", 48, math.max(#rows + 2, 16), rows, {
            background = { 0, 0, 0, 0.9 }
        })
    end,
})

UI.register("controls", {
    order = 30,
    position = function(_, widget, widgets)
        return UI.left_column_x(widget), UI.below(widgets, "inventory")
    end,
    visible = function(context)
        return context.player ~= nil
    end,
    build = function(context)
        local player = context.player
        local content

        if player and player.ui and player.ui.level_up_open then
            content = {
                {
                    { text = " LEFT/RIGHT tab", color = Colors.reset }
                },
                {
                    { text = " UP/DOWN   select", color = Colors.reset }
                },
                {
                    { text = " E/ENTER   choose", color = Colors.reset }
                },
                {
                    { text = " Q         close", color = Colors.reset }
                },
            }
        elseif player and player.ui and player.ui.chest_open then
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
                    { text = " E equip/interact", color = Colors.reset }
                },
                {
                    { text = " I inventory", color = Colors.reset }
                },
                {
                    { text = " L level rewards", color = Colors.reset }
                },
            }
        end

        return UI.box("Controls", 24, 7, content)
    end,
})

Registry.register("systems", "ui", UI)

return UI
