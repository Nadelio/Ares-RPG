local Renderable = {} 

function Renderable.new(glyph)
    return {
        glyph = glyph or "?"
    } 
end

return Renderable 