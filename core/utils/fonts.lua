local Fonts = {}

function Fonts.init()
    if Fonts.main then return end
    Fonts.main = love.graphics.newFont("assets/fonts/unifont-17.0.05.otf")
    love.graphics.setFont(Fonts.main)
end

return Fonts