local function rgb(r, g, b)
    return {
        r / 255,
        g / 255,
        b / 255
    }
end

local RarityColors = {
    common    = rgb(204, 204, 204),
    uncommon  = rgb(102, 255, 102),
    rare      = rgb(102, 153, 255),
    epic      = rgb(230, 102, 255),
    legendary = rgb(255, 204,  51),
    cursed    = rgb( 99,  13, 209),
    coin      = rgb(255, 255,  77),
}

return RarityColors 