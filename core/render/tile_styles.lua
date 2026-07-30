local ConstTable = require("core.utils.const_table")

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

local mask_constants = ConstTable.new({
    NONE = 0,
    TOP = 1,
    RIGHT = 2,
    TR_CORNER = 3,
    BOTTOM = 4,
    TB_LINE = 5,
    BR_CORNER = 6,
    RIGHT_INTERSECTION = 7,
    LEFT = 8,
    TL_CORNER = 9,
    RL_LINE = 10,
    TOP_INTERSECTION = 11,
    BL_CORNER = 12,
    LEFT_INTERSECTION = 13,
    BOTTOM_INTERSECTION = 14,
    ALL = 15,
})

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

    -- isolated wall -> treat like pillar
    if m == mask_constants.NONE then return "●" end

    -- straight lines
    if m == mask_constants.TOP or m == mask_constants.BOTTOM or m == (mask_constants.TOP + mask_constants.BOTTOM) then return "│" end
    if m == mask_constants.RIGHT or m == mask_constants.LEFT or m == (mask_constants.RIGHT + mask_constants.LEFT) then return "─" end

    -- corners
    if m == mask_constants.TR_CORNER then return "╰" end
    if m == mask_constants.TL_CORNER then return "╯" end
    if m == mask_constants.BR_CORNER then return "╭" end
    if m == mask_constants.BL_CORNER then return "╮" end

    if m == mask_constants.RIGHT_INTERSECTION then return "├" end
    if m == mask_constants.LEFT_INTERSECTION then return "┤" end
    if m == mask_constants.TOP_INTERSECTION then return "┴" end
    if m == mask_constants.BOTTOM_INTERSECTION then return "┬" end
    if m == mask_constants.ALL then return "┼" end

    -- thick walls
    local has_lr = (
        m == mask_constants.RL_LINE or
        m == mask_constants.TOP_INTERSECTION or
        m == mask_constants.BOTTOM_INTERSECTION or
        m == mask_constants.ALL
    )
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