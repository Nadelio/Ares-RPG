local Registry = require("core.registry")

local MapGenerator = {}

local MIN_LEAF_SIZE = 5
local ROOM_MIN_DIM  = 3
local HORIZONTAL_TOLERANCE = 4.0
local VERTICAL_TOLERANCE = 2.0
local DEFAULT_DEPTH = 6
local DEFAULT_MAP_DIMS = {
    WIDTH = 60,
    HEIGHT = 40
}

local function new_node(x, y, w, h)
    return { x = x, y = y, w = w, h = h, left = nil, right = nil, room = nil }
end

local function split(node)
    if node.left or node.right then return false end

    local split_horiz
    if   node.w > node.h and node.w / node.h >= HORIZONTAL_TOLERANCE then
        split_horiz = false
    elseif node.h > node.w and node.h / node.w >= VERTICAL_TOLERANCE then
        split_horiz = true
    else
        split_horiz = math.random(0, 1) == 1
    end

    local dim       = split_horiz and node.h or node.w
    local max_split = dim - MIN_LEAF_SIZE
    if max_split < MIN_LEAF_SIZE then return false end

    local pos = math.random(MIN_LEAF_SIZE, max_split)
    if split_horiz then
        node.left  = new_node(node.x, node.y,       node.w, pos + 1)
        node.right = new_node(node.x, node.y + pos, node.w, node.h - pos)
    else
        node.left  = new_node(node.x,       node.y, pos + 1,      node.h)
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
    if node.w < ROOM_MIN_DIM or node.h < ROOM_MIN_DIM then return end

    node.room = { x = node.x, y = node.y, w = node.w, h = node.h }

    for cy = node.y + 1, node.y + node.h - 2 do
        for cx = node.x + 1, node.x + node.w - 2 do
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

local function place_objects(world, map)
    local valid_objects = Registry.query("prefabs", function(prefab)
        if prefab.new({}).position and prefab.new({}).renderable and prefab.new({}).placement_rules then
            return true
        end
        return false
    end)

    for _, obj in ipairs(valid_objects) do
        local proto = obj.new({})
        local obj_rules = proto.placement_rules
        for y = 1, #map.tiles do
            for x = 1, #map.tiles[y] do
                if obj_rules.valid_placement(x, y, map) then
                    if proto.dynamic then
                        world:add(obj.new({ x = x, y = y }))
                    else
                        map:add_object(obj.new({ x = x, y = y }))
                    end
                end
            end
        end
    end
end

function MapGenerator.init(Events, world, map, logger)
    Events.on("build_map", function(e)
        local w = (e.dimensions and e.dimensions.w) or DEFAULT_MAP_DIMS.WIDTH
        local h = (e.dimensions and e.dimensions.h) or DEFAULT_MAP_DIMS.HEIGHT
        local max_depth = e.depth or DEFAULT_DEPTH

        local tiles = {}
        for y = 1, h do
            tiles[y] = {}
            for x = 1, w do
                tiles[y][x] = { type = "W" }
            end
        end

        local root = new_node(1, 1, w, h)
        split_recursive(root, max_depth)
        carve_rooms(root, tiles)
        connect_nodes(root, tiles)
        logger:add("Generated Map")

        local spawn = find_first_room(root)
        if spawn and world.player and world.player.position then
            local sx, sy = room_center(spawn)
            tiles[sy][sx] = { type = "X" }
            world.player.position.x = sx
            world.player.position.y = sy
        end
        logger:add("Player Placed")
        map.tiles   = tiles

        place_objects(world, map)
        logger:add("Objects and Entities Placed")
    end, 100)
end

Registry.register("systems", "map_generator", MapGenerator)

return MapGenerator