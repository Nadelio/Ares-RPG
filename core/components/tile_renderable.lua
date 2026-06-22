local TileRenderable = {} 

function TileRenderable.new(data)
    return {
        glyph = data.glyph or " ",
        variant = data.variant or "solid",
        override = data.override
    } 
end

return TileRenderable 