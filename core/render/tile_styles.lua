local TileStyles = {}

local function isWall(map, x, y)
    if x < 1 or y < 1 then return false end

    local row = map.tiles[y]
    if not row then return false end

    local tile = row[x]
    if not tile then return false end

    return tile.type == "W"
end

local function isWallOrOOB(map, x, y)
    if x < 1 or y < 1 then return true end

    local row = map.tiles[y]
    if not row then return true end

    local tile = row[x]
    if not tile then return true end

    return tile.type == "W"
end

local function isVisibleWall(map, x, y)
    if not isWall(map, x, y) then return false end
    -- buried when every surrounding cell is wall or outside the map
    return not (
        isWallOrOOB(map, x - 1, y - 1) and isWallOrOOB(map, x, y - 1) and isWallOrOOB(map, x + 1, y - 1)
        and isWallOrOOB(map, x - 1, y)                                  and isWallOrOOB(map, x + 1, y)
        and isWallOrOOB(map, x - 1, y + 1) and isWallOrOOB(map, x, y + 1) and isWallOrOOB(map, x + 1, y + 1)
    )
end

local function mask(map, x, y)
    local m = 0

    if isVisibleWall(map, x,     y - 1) then m = m + 1 end -- above
    if isVisibleWall(map, x + 1, y    ) then m = m + 2 end -- right
    if isVisibleWall(map, x,     y + 1) then m = m + 4 end -- below
    if isVisibleWall(map, x - 1, y    ) then m = m + 8 end -- left

    return m
end

TileStyles.W = function(x, y, map)
    if not isVisibleWall(map, x, y) then return " " end

    local non_wall_count = 0
    local ndx, ndy = 0, 0
    for dy = -1, 1 do
        for dx = -1, 1 do
            if not (dx == 0 and dy == 0) and not isWallOrOOB(map, x + dx, y + dy) then
                non_wall_count = non_wall_count + 1
                ndx, ndy = dx, dy
            end
        end
    end
    if non_wall_count == 1 and ndx ~= 0 and ndy ~= 0 then
        if ndx ==  1 and ndy ==  1 then return "╭" end  -- open space is bottom-right
        if ndx == -1 and ndy ==  1 then return "╮" end  -- open space is bottom-left
        if ndx ==  1 and ndy == -1 then return "╰" end  -- open space is top-right
        if ndx == -1 and ndy == -1 then return "╯" end  -- open space is top-left
    end

    local m = mask(map, x, y)

    -- isolated wall
    if m == 0 then return "█" end

    -- straight lines
    if m == 1 or m == 4 or m == 5 then return "│" end
    if m == 2 or m == 8 or m == 10 then return "─" end

    -- corners
    if m == 1 + 2 then return "╰" end
    if m == 1 + 8 then return "╯" end
    if m == 4 + 2 then return "╭" end
    if m == 4 + 8 then return "╮" end

    -- thick walls
    local has_lr = (m == 10 or m == 11 or m == 14 or m == 15)
    if has_lr then return "─" end
    return "│"
end

TileStyles.X = function()
    return " "
end

TileStyles.C = function()
    return " "
end

return TileStyles