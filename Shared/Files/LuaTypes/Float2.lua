--- Float2 module.
-- @module Float2

Float2 = {}

function Float2:new(x, y)

    local o = {
        id = "Float2"
    }
    
    if x == nil then
        o.x = 0
        o.y = 0
    elseif y == nil then
        o.x = x
        o.y = x
    else
        o.x = x
        o.y = y
    end

    setmetatable(o, self)
    self.__index = self
    return o
end

return Float2
