---@type table|fun(x: number?, y:number?):vec2
local vec2 = { }
local mt = { }

---@class vec2
---@field x number
---@field y number
---@field set fun(self: vec2, vec: vec2): vec2
---@field setxy fun(self: vec2, x: number, y: number): vec2
---@field add fun(self: vec2, vec: vec2): vec2
---@field addxy fun(self: vec2, x: number, y: number): vec2
---@field sub fun(self: vec2, vec: vec2): vec2
---@field subxy fun(self: vec2, x: number, y: number): vec2

---@return vec2
---@param x number?
---@param y number?
function vec2.new(x, y)
    return setmetatable({
        [1] = x or 0, 
        [2] = y or 0
    }, mt)
end

---@return vec2
function vec2.copy(vec)
    return vec2.new(vec.x, vec.y)
end

setmetatable(vec2, {
    __call = function(v, x, y)
        return vec2.new(x, y)
    end
})

-- make sure you dont change that
vec2.zero = vec2()

do
    local methods = { }

    function methods:set(vec)
        self.x = vec.x
        self.y = vec.y

        return self
    end

    function methods:setxy(x, y)
        self.x = x
        self.y = y

        return self
    end

    function methods:subxy(x, y)
        self.x = self.x - x
        self.y = self.y - y

        return self
    end

    function methods:sub(v)
        self.x = self.x - v.x
        self.y = self.y - v.y

        return self
    end

    function methods:add(v)
        self.x = self.x + v.x
        self.y = self.y + v.y

        return self
    end

    function methods:addxy(x, y)
        self.x = self.x + x
        self.y = self.y + y

        return self
    end

    function mt.__index(v, k)
        if k == 1 or k == 2 then
            return rawget(v, k)
        end

        if k == "x" then 
            return v[1]
        end

        if k == "y" then
            return v[2]
        end

        if methods[k] then 
            return methods[k]
        end
    end

    function mt.__newindex(v, k, sv)
        if k == "x" then 
            v[1] = sv
        elseif k == "y" then
            v[2] = sv
        end
    end

    function mt.__add(o1, o2) 
        return vec2.new(
            o1[1] + o2[1], 
            o1[2] + o2[2]
        )
    end

    function mt.__sub(o1, o2)
        return vec2.new(
            o1[1] - o2[1],
            o1[2] - o2[2]
        )
    end

    function mt.__unm(o)
        return vec2.new(-o[1], -o[2])
    end

    function mt.__mul(o1, o2)
        if type(o2) == "number" then
            return vec2.new(o1[1] * o2, o1[2] * o2)
        else
            return vec2.new(o1[1] * o2[1], o1[2] * o2[2])
        end
    end

    function mt.__div(o1, o2)
        if type(o2) == "number" then
            return vec2.new(o1[1] / o2, o1[2] / o2)
        else
            return vec2.new(o1[1] / o2[1], o1[2] / o2[2])
        end
    end

    function mt.__lt(o1, o2)
        return o1[1] < o2[1] and o1[2] < o2[2] 
    end

    function mt.__le(o1, o2)
        return o1[1] <= o2[1] and o1[2] <= o2[2]
    end
end

return vec2
