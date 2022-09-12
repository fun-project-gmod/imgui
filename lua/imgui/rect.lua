local vec2 = grequire "imgui.vec2"

---@class rect
---@field min vec2
---@field max vec2
---@field contains fun(self:rect, pos:vec2):boolean
---@field center fun(self:rect):vec2

local rect = { }
local mt = { }

---@return rect
---@param p1 vec2
---@param p2 vec2
function rect.new(p1, p2)
    return setmetatable({
        [1] = p1,
        [2] = p2
    }, mt)
end

---@return rect
function rect.copy(r)
    return rect.new(r[1], r[2])
end

setmetatable(rect, {
    __call = function(v, p1, p2)
        return rect.new(p1, p2)
    end
})

do 
    local methods = { }

    function methods:contains(pos)
        return self[1] <= pos and self[2] >= pos
    end

    function methods:center()
        return (self[1] + self[2]) / 2
    end

    function mt.__index(v, k)
        if k == 1 or k == 2 then
            return rawget(v, k)
        end

        if k == "min" then
            return v[1]
        end

        if k == "max" then
            return v[2]
        end

        if methods[k] then
            return methods[k]
        end
    end

    function mt.__newindex(v, k, sv)
        if k == "min" then
            v[1] = sv
        elseif k == "max" then
            v[2] = sv
        end
    end
end

return rect