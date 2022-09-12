local vec2 = grequire "imgui.vec2"

local scaling = { }

function scaling.setBaseResolution(w, h)
    scaling.baseres = vec2(w, h)
    return scaling
end

function scaling.setTargetResolution(w, h)
    scaling.targetres = vec2(w, h)
    scaling.scalefactor = scaling.targetres / scaling.baseres
    return scaling
end

function scaling.scale(vec)
    return vec * scaling.scalefactor
end

function scaling.scaled(x, y)
    return scaling.scale(vec2.new(x, y))
end
scaling.new = scaling.scaled

setmetatable(scaling, {
    __call = function(t, x, y)
        return scaling.new(x, y)
    end
})

return scaling