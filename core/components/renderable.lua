local Colors = require("core.render.colors")
local Renderable = {} 

function Renderable.new(data)
    return {
        glyph = data.glyph or "?",
        fg = data.fg or Colors.reset,
        bg = data.bg or Colors.black,
        italics = data.italics or false,
        bold = data.bold or false,
        underline = data.underline or false
    }
end

return Renderable 