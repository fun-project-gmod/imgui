local vec2 = grequire "imgui.vec2"
local imgui = grequire "imgui.imgui"
local io = imgui.io

local drag = { }

function drag.begin(rect, base)
    if io.clickable(rect) then
        base = base or rect.min
        
        return {
            rect = rect,
            base = base,
            moffset = io.mousePos() - rect.min,

            -- output
            pos = base,
            posRelative = rect.min - base
        }
    end
end

function drag.update(dragging)
    if not dragging then return end
    if not io.mouse[MOUSE_LEFT].pressed then
        return
    end

    dragging.pos = io.mousePos() - dragging.moffset
    dragging.posRelative = dragging.pos - dragging.base
    return dragging
end

--[[
    local dragging

    function update()
        dragging = drag.update(dragging) or drag.begin(titlebar:rect())

        if dragging then
            window.pos = dragging.pos
        end
    end
]]

return drag