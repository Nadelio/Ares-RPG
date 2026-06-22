local Vec2 = {}
Vec2.__index = Vec2

function Vec2.new(x, y) return setmetatable({x=x or 0, y=y or 0}, Vec2) end
function Vec2.__add(a, b) return Vec2.new(a.x+b.x, a.y+b.y) end
function Vec2.__sub(a, b) return Vec2.new(a.x-b.x, a.y-b.y) end
function Vec2.__mul(a, b)
    if type(b) == "number" then -- if Vec2 * int or Vec2 * float
        return Vec2.new(a.x * b, a.y * b)  -- scalar multiplication
    elseif type(b) == "table" and getmetatable(b) == Vec2 then -- if Vec2 * Vec2
        return Vec2.new(a.x * b.y, b.x * a.y)  -- cross product
    end
end
function Vec2.__div(v1, v2)
    if type(v2) == "number" then -- if Vec2 / int or Vec2 / float
        if v2 == 0 then error("Div by zero") end
        return Vec2.new(v1.x / v2, v1.y / v2) -- scalar division
    elseif type(v1) == "number" then -- if int / Vec2 or float / Vec2
        if v2.x == 0 or v2.y == 0 then error("Div by zero") end
        return Vec2.new(v1 / v2.x, v1 / v2.y) -- scalar division
    elseif getmetatable(v1) == Vec2 and getmetatable(v2) == Vec2 then -- if Vec2 / Vec2
        if v2.x == 0 or v2.y == 0 then error("Div by zero") end
        return Vec2.new(v1.x / v2.x, v1.y / v2.y) -- element division
    end
end
function Vec2:length() return math.sqrt(self.x^2 + self.y^2) end
function Vec2.__eq(a, b) return a.x == b.x and a.y == b.y end
function Vec2:__tostring() return string.format("<%.2f, %.2f>", self.x, self.y) end

Vec2.dot = function(a, b)
    if type(a) == type(b) and type(a) == "table" and getmetatable(a) == Vec2 then
        return (a.x * b.x) + (a.y * b.y) 
    else
        assert(type(a) == type(b) and type(a) == "table" and getmetatable(a) == Vec2, "Vec2.dot was not given two Vec2's.") 
    end
end
function Vec2:normal()
    local mag = #self 
    if mag == 0 then
        -- return a zero vector to prevent crash/NaN errors if length is zero
        return Vec2.zero 
    end
    return self / mag 
end
Vec2.zero = Vec2.new() 

return Vec2