-- there is a certain optimization that can be made for this lib: poly caching
-- so instead of recreating the poly table every frame for every draw call, you instead chche it for the exact same table
-- and you just edit the positions in it afterwards
-- that should be a whole lot faster (especially in gmod, alot of shit is allocated already so alloc calls are expensive asf)
-- and more memory efficient
-- also saves time on garbage collection passes

local vec2 = grequire "imgui.vec2"
local imgui = grequire "imgui.imgui"

local drawing = { }

function drawing.rect(pos, size, r, g, b, a)
    surface.SetDrawColor(r, g, b, a)
    surface.DrawRect(
        pos[1], pos[2],
        size[1], size[2]
    )
end

function drawing.rectAbs(pos1, pos2, r, g, b, a)
    drawing.rect(pos1, pos2 - pos1, r, g, b, a)
end

function drawing.filledCircle(pos, radius, seg, actualSeg, r, g, b, a)
    if not actualSeg then actualSeg = seg end
    local x, y = pos[1], pos[2]

    local elem = { }

    table.insert(elem, { x = x, y = y })
    for i = 0, seg do
        local n = i / actualSeg * math.pi * -2

        local sx, sy =
            x + math.sin(n) * radius,
            y + math.cos(n) * radius

        sx = math.min(math.max(sx, 0), ScrW())
        sy = math.min(math.max(sy, 0), ScrH())

        table.insert(elem, {
            x = sx,
            y = sy
        })
    end

    surface.SetDrawColor(r, g, b, a)
    surface.DrawPoly(elem)
end

-- this is to be used with stencils if you have alpha
-- can be improved by just doing drawpoly instead of all that
function drawing.roundedRect(pos, size, rounding, r, g, b, a, tl, tr, bl, br, detail)
    if tl == nil then tl = true end
    if tr == nil then tr = true end
    if bl == nil then bl = true end
    if br == nil then br = true end

    detail = detail or 36

    drawing.rect(pos + vec2.new(rounding, 0), size - vec2.new(rounding * 2, 0), 255, 255, 255, 255)
    drawing.rect(pos + vec2.new(0, rounding), size - vec2.new(0, rounding * 2), 255, 255, 255, 255)

    local rv = vec2.new(rounding, rounding)
    if tl then
        drawing.filledCircle(pos + rv, rounding, detail, detail, r, g, b, a)
    else
        drawing.rect(pos, rv, r, g, b, a)
    end

    if br then
        drawing.filledCircle(pos + size - rv, rounding, detail, detail, r, g, b, a)
    else
        drawing.rect(pos + size - rv, rv, r, g, b, a)
    end

    if tr then
        drawing.filledCircle(pos + vec2.new(-rounding + size.x, rounding), rounding, detail, detail, r, g, b, a)
    else
        drawing.rect(pos + vec2.new(-rounding + size.x, 0), rv, r, g, b, a)
    end

    if br then 
        drawing.filledCircle(pos + vec2.new(rounding, -rounding + size.y), rounding, detail, detail, r, g, b, a)
    else
        drawing.rect(pos + vec2.new(0, -rounding + size.y), rv, r, g, b, a)
    end
end

function drawing.text(pos, font, text, r, g, b, a)
    font:apply()
    surface.SetTextColor(r, g, b, a)
    surface.SetTextPos(pos[1], pos[2])
    surface.DrawText(text)
end

function drawing.image(pos, material, size, r, g, b, a, rotation)
    material:SetInt("$flags", bit.bor(material:GetInt("$flags"), 2^15))
    rotation = rotation or 0

    surface.SetMaterial(material)
    surface.SetDrawColor(r, g, b, a)
    if rotation == 0 then 
        surface.DrawTexturedRect(pos[1], pos[2], size[1], size[2])
    else
        surface.DrawTexturedRectRotated(pos[1] + size[1] / 2, pos[2] + size[2] / 2, size[1], size[2], rotation)
    end
end

do 
    local clip = {
        depth = 0,
        status = 0
    }

    function clip.clear()
        render.SetStencilWriteMask(0xFFFF)
        render.SetStencilTestMask(0xFFFF)
        render.SetStencilReferenceValue(0)
        render.SetStencilCompareFunction(STENCIL_ALWAYS)
        render.SetStencilPassOperation(STENCIL_KEEP)
        render.SetStencilFailOperation(STENCIL_KEEP)
        render.SetStencilZFailOperation(STENCIL_KEEP)
        render.ClearStencil()
    end

    function clip.enable()
        render.SetStencilEnable(true)
    end

    function clip.disable()
        render.SetStencilEnable(false)
    end

    function clip.record()
        clip.leave()
        render.SetStencilCompareFunction(STENCIL_EQUAL)
        render.SetStencilPassOperation(STENCIL_INCR)
        clip.status = 1
    end

    function clip.apply()
        clip.enter()
        render.SetStencilPassOperation(STENCIL_KEEP)
        render.SetStencilCompareFunction(STENCIL_EQUAL)
        clip.status = 2
    end

    function clip.enter()
        clip.depth = clip.depth + 1
        render.SetStencilReferenceValue(clip.depth)
    end

    function clip.leave()
        render.SetStencilReferenceValue(clip.depth)
        render.SetStencilCompareFunction(STENCIL_EQUAL)
        render.SetStencilPassOperation(STENCIL_DECR)
        render.PerformFullScreenStencilOperation()

        clip.depth = clip.depth - 1
        render.SetStencilReferenceValue(clip.depth)
        render.SetStencilPassOperation(STENCIL_KEEP)
    end

    drawing.clip = clip
end

return drawing