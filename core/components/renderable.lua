local Registry = require("core.registry")
local Colors = require("core.render.colors")
local Renderable = {} 

function Renderable.new(data)
    local sprite = data.sprite or data

    return {
        glyph = data.glyph or "?",
        fg = data.fg or Colors.reset,
        bg = data.bg or Colors.black,
        italics = data.italics or false,
        bold = data.bold or false,
        underline = data.underline or false,
        sprite = {
            x = sprite.x or 0,
            y = sprite.y or 0,
            atlas_path = sprite.atlas_path or "./assets/textures/atlas_16px.png",
            resolution = sprite.resolution or 16
        }
    }
end

Registry.register("components", "renderable", Renderable)

return Renderable 