local TileStyles = {}

local function isWall(map, x, y)
    if x < 1 or y < 1 then return false end

    local row = map.tiles[y]
    if not row then return false end

    local tile = row[x]
    if not tile then return false end

    return tile.type == "W"
end

local function mask(map, x, y)
    local m = 0

    if isWall(map, x, y - 1) then m = m + 1 end -- above
    if isWall(map, x + 1, y) then m = m + 2 end -- right
    if isWall(map, x, y + 1) then m = m + 4 end -- below
    if isWall(map, x - 1, y) then m = m + 8 end -- left

    return m
end

TileStyles.W = function(x, y, map)

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

    -- T-junctions
    if m == 1 + 2 + 4 then return "├" end
    if m == 1 + 8 + 4 then return "┤" end
    if m == 1 + 2 + 8 then return "┴" end
    if m == 2 + 4 + 8 then return "┬" end

    -- cross
    if m == 1 + 2 + 4 + 8 then return "┼" end

    return "█"
end

TileStyles.X = function()
    return " "
end

return TileStyles