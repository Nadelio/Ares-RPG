local Sprites = {}

--? Used in sprite rendering mode for anything that doesn't carry its own sprite
--? (map tiles, ghost previews, blank cells)
Sprites.DEFAULT_SPRITE = {
    x = 0,
    y = 0,
    atlas_path = "./assets/textures/atlas_16px.png",
    resolution = 16,
    rotation = 0
}

local atlas_cache = {}
local quad_cache = {}

--? Only 90 degree rotations are supported, snap anything else to the nearest
--? quarter turn and wrap into the 0-270 range
function Sprites.normalize_rotation(rotation)
    if not rotation then
        return 0
    end

    return (math.floor((rotation / 90) + 0.5) * 90) % 360
end

function Sprites.get_atlas(path)
    local atlas = atlas_cache[path]

    if not atlas then
        --? love.filesystem paths must not start with "./"
        atlas = love.graphics.newImage((path:gsub("^%./", "")))
        atlas_cache[path] = atlas
    end

    return atlas
end

function Sprites.get_quad(sprite, atlas)
    local key = sprite.atlas_path .. ":" .. sprite.x .. "," .. sprite.y .. "," .. sprite.resolution

    local quad = quad_cache[key]

    if not quad then
        --? sprite.x/sprite.y are cell indices into the atlas, not pixel offsets
        quad = love.graphics.newQuad(
            sprite.x * sprite.resolution,
            sprite.y * sprite.resolution,
            sprite.resolution,
            sprite.resolution,
            atlas:getDimensions()
        )
        quad_cache[key] = quad
    end

    return quad
end

--? Draws a sprite into the rectangle (x, y, width, height), applying the
--? sprite's 90-degree rotation around the rectangle's center.
--? `rotation_offset` (optional) is added on top of the sprite's own rotation.
--? The caller is responsible for setting the draw color beforehand.
function Sprites.draw(sprite, x, y, width, height, rotation_offset)
    local atlas = Sprites.get_atlas(sprite.atlas_path)
    local quad = Sprites.get_quad(sprite, atlas)
    local rotation = Sprites.normalize_rotation((sprite.rotation or 0) + (rotation_offset or 0))

    --? upscale/downscale sprites to the requested size
    --? (Ex: 16px sprites are drawn at 2x when the target size is 32)
    local scale_x = width / sprite.resolution
    local scale_y = height / sprite.resolution

    if rotation == 0 then
        love.graphics.draw(atlas, quad, x, y, 0, scale_x, scale_y)
        return
    end

    --? Quarter turns swap the sprite's axes, so swap the scales to keep the
    --? drawn footprint at width x height
    if rotation == 90 or rotation == 270 then
        scale_x, scale_y = scale_y, scale_x
    end

    love.graphics.draw(
        atlas,
        quad,
        x + width / 2,
        y + height / 2,
        math.rad(rotation),
        scale_x,
        scale_y,
        sprite.resolution / 2,
        sprite.resolution / 2
    )
end

return Sprites
