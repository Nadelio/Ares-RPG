local Logger = {} 
Logger.__index = Logger 

function Logger.new()
    return setmetatable({
        turn = 1,
        events = {}
    }, Logger) 
end

function Logger:add(eventType, format_fn, data)
    local entry = {
        turn = self.turn,
        type = eventType,
        format = format_fn,
        data = data or {}
    } 

    table.insert(self.events, entry) 

    self.turn = self.turn + 1 

    return entry 
end

function Logger:next_turn()
    self.turn = self.turn + 1 
end

function Logger:save(path)
    local lines = {}
    for _, event in ipairs(self.events) do
        table.insert(lines, self:format(event))
    end
    local content = table.concat(lines, "\n")
    if #content > 0 then
        content = content .. "\n"
    end

    if love and love.filesystem then
        local dir = path:match("^(.*)[/\\][^/\\]+$")
        if dir and dir ~= "" then
            love.filesystem.createDirectory(dir)
        end

        local ok, err = love.filesystem.write(path, content)
        if not ok then
            print("Could not save log to " .. path .. " : " .. tostring(err))
        end
        return ok
    end

    local file, err = io.open(path, "w")
    if not file then
        print("Could not save log to " .. path .. " : " .. tostring(err))
        return false
    end

    file:write(content)
    file:close()
    return true
end

function Logger:format(event)

    if event.format then
        return event.format(event)
    end

    if event.type == "move" then
        return string.format(
            "[Action %d] MOVE %s (%d,%d -> %d,%d)",
            event.turn,
            event.data.entity,
            event.data.from.x, event.data.from.y,
            event.data.to.x, event.data.to.y
        ) 

    elseif event.type == "attack" then
        return string.format(
            "[Action %d] ATTACK %s -> %s (%d dmg)",
            event.turn,
            event.data.attacker,
            event.data.target,
            event.data.damage
        ) 

    elseif event.type == "interact" then
        return string.format(
            "[Action %d] INTERACT %s -> %s (%s)",
            event.turn,
            event.data.actor,
            event.data.target,
            event.data.type
        ) 

    elseif event.type == "inventory_equip" then
        return string.format(
            "[Action %d] EQUIP %s -> %s",
            event.turn,
            event.data.target,
            event.data.actor
        )
    elseif event.type == "inventory_unequip" then
        return string.format(
            "[Action %d] UNEQUIP %s -> %s",
            event.turn,
            event.data.target,
            event.data.actor
        )
    elseif event.type == "inventory_pickup" then
        return string.format(
            "[Action %d] PICKUP %s -> %s",
            event.turn,
            event.data.target,
            event.data.actor
        )
    elseif event.type == "inventory_drop" then
        return string.format(
            "[Action %d] DROP %s -> %s",
            event.turn,
            event.data.target,
            event.data.actor
        )
    elseif event.type == "level_up" then
        return string.format(
            "[Action %d] LEVEL UP %s (+%d LV -> %d)",
            event.turn,
            event.data.entity,
            event.data.levels or 1,
            event.data.new_level or 1
        ) 
    end

    return string.format(
        "[Action %d] %s",
        event.turn,
        event.type
    ) 
end

return Logger 