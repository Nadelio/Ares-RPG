local Registry = require("core.registry")

local MapGenerator = {}

local MIN_LEAF_SIZE = 8
local ROOM_PADDING  = 1
local ROOM_MIN_DIM  = 4

local function new_node(x, y, w, h)
    return { x = x, y = y, w = w, h = h, left = nil, right = nil, room = nil }
end

local function split(node)
    if node.left or node.right then return false end

    local split_horiz
    if   node.w > node.h and node.w / node.h >= 1.25 then
        split_horiz = false
    elseif node.h > node.w and node.h / node.w >= 1.25 then
        split_horiz = true
    else
        split_horiz = math.random(0, 1) == 1
    end

    local dim       = split_horiz and node.h or node.w
    local max_split = dim - MIN_LEAF_SIZE
    if max_split < MIN_LEAF_SIZE then return false end

    local pos = math.random(MIN_LEAF_SIZE, max_split)

    if split_horiz then
        node.left  = new_node(node.x, node.y,       node.w, pos)
        node.right = new_node(node.x, node.y + pos, node.w, node.h - pos)
    else
        node.left  = new_node(node.x,       node.y, pos,          node.h)
        node.right = new_node(node.x + pos, node.y, node.w - pos, node.h)
    end

    return true
end

local function split_recursive(node, depth)
    if depth <= 0 then return end
    if split(node) then
        split_recursive(node.left,  depth - 1)
        split_recursive(node.right, depth - 1)
    end
end

local function carve_room(node, tiles)
    local max_w = node.w - ROOM_PADDING * 2
    local max_h = node.h - ROOM_PADDING * 2
    if max_w < ROOM_MIN_DIM or max_h < ROOM_MIN_DIM then return end

    local rw = math.random(ROOM_MIN_DIM, max_w)
    local rh = math.random(ROOM_MIN_DIM, max_h)
    local ox = math.random(0, max_w - rw)
    local oy = math.random(0, max_h - rh)
    local rx = node.x + ROOM_PADDING + ox
    local ry = node.y + ROOM_PADDING + oy

    node.room = { x = rx, y = ry, w = rw, h = rh }

    for cy = ry + 1, ry + rh - 2 do
        for cx = rx + 1, rx + rw - 2 do
            tiles[cy][cx] = { type = "X" }
        end
    end
end

local function carve_rooms(node, tiles)
    if node.left or node.right then
        if node.left  then carve_rooms(node.left,  tiles) end
        if node.right then carve_rooms(node.right, tiles) end
    else
        carve_room(node, tiles)
    end
end

local function nearest_room(node)
    if node.room then return node.room end
    local l = node.left  and nearest_room(node.left)
    local r = node.right and nearest_room(node.right)
    if not l then return r end
    if not r then return l end
    return math.random(0, 1) == 0 and l or r
end

local function room_center(room)
    return math.floor(room.x + room.w / 2),
           math.floor(room.y + room.h / 2)
end

local function carve_hline(tiles, y, x1, x2)
    local step = x2 >= x1 and 1 or -1
    for x = x1, x2, step do
        local row = tiles[y]
        if row and row[x] and row[x].type == "W" then
            row[x] = { type = "C" }
        end
    end
end

local function carve_vline(tiles, x, y1, y2)
    local step = y2 >= y1 and 1 or -1
    for y = y1, y2, step do
        if tiles[y] and tiles[y][x] and tiles[y][x].type == "W" then
            tiles[y][x] = { type = "C" }
        end
    end
end

local function connect_rooms(tiles, ax, ay, bx, by)
    if math.random(0, 1) == 0 then
        carve_hline(tiles, ay, ax, bx)
        carve_vline(tiles, bx, ay, by)
    else
        carve_vline(tiles, ax, ay, by)
        carve_hline(tiles, by, ax, bx)
    end
end

local function connect_nodes(node, tiles)
    if not node.left or not node.right then return end
    connect_nodes(node.left,  tiles)
    connect_nodes(node.right, tiles)

    local la = nearest_room(node.left)
    local rb = nearest_room(node.right)
    if la and rb then
        local ax, ay = room_center(la)
        local bx, by = room_center(rb)
        connect_rooms(tiles, ax, ay, bx, by)
    end
end

local function find_first_room(node)
    if node.room then return node.room end
    return (node.left  and find_first_room(node.left))
        or (node.right and find_first_room(node.right))
end

-- TODO: Add a placer function to place objects/interactables/entities (anything with both a Renderable component and a Position component)
function MapGenerator.init(Events, world, map, logger)
    Events.on("build_map", function(e)
        local w = (e.dimensions and e.dimensions.w) or 60
        local h = (e.dimensions and e.dimensions.h) or 40

        local tiles = {}
        for y = 1, h do
            tiles[y] = {}
            for x = 1, w do
                tiles[y][x] = { type = "W" }
            end
        end

        local root = new_node(1, 1, w, h)
        split_recursive(root, 5)
        carve_rooms(root, tiles)
        connect_nodes(root, tiles)

        local spawn = find_first_room(root)
        if spawn and world.player and world.player.position then
            local sx, sy = room_center(spawn)
            tiles[sy][sx] = { type = "X" }
            world.player.position.x = sx
            world.player.position.y = sy
        end

        map.tiles   = tiles
        logger:add("Generated Map")
        logger:add("Player Placed")
        map.objects = {}
        logger:add("Objects and Entities Placed")
    end, 100)
end

Registry.register("systems", "map_generator", MapGenerator)

return MapGenerator