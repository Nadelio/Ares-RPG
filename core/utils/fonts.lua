local Fonts = {} 

function Fonts.init()
    if Fonts.main then return end
    Fonts.main = love.graphics.newFont("assets/fonts/FiraCode.ttf") 
    love.graphics.setFont(Fonts.main) 
end

return Fonts 