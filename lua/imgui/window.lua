local rect = grequire "imgui.rect"
local vec2 = grequire "imgui.vec2"

---@class imuserwindowsettings
---@field pos? vec2
---@field startpos? vec2
---@field size vec2
---@field noDrag? boolean
---@field noScroll? boolean
---@field noDecoration? boolean
---@field zindex? number

---@class imwindowsettings : imuserwindowsettings
---@field name string
---@field settings imuserwindowsettings

---@class imwindow : imwindowsettings
---@field previousCursor vec2
---@field previousCursorMove vec2?
---@field cursor vec2
---@field contentSize vec2?
---@field callback fun()
---@field rect fun(self: imwindow): rect
---@field elements table<string, table>
---@field furthestPoint vec2
---@field basePoint vec2?
---@field basePointNoScroll vec2?
---@field scrolly number
---@field autoSize boolean
---@field topSize vec2?
---@field windows table<string, imwindow>
---@field parent imwindow?
---@field getRootWindow fun(self: imwindow): imwindow
---@field drawn boolean?
---@field style table
---@field styleOverrides table

local window = { }
local mt = { }

---@param settings imwindowsettings
---@return imwindow
function window.new(settings) 
    return setmetatable({
        size = settings.size or vec2(),
        pos = settings.pos or vec2(100, 100),
        zindex = settings.zindex,
        name = settings.name,
        settings = settings.settings,

        autoSize = not settings.size,
        cursor = vec2(),
        previousCursor = vec2(),
        contentSize = vec2(),
        elements = { },
        basePoint = vec2(),
        basePointNoScroll = vec2(),
        scrolly = 0,
        furthestPoint = vec2(),
        windows = { },
        topSize = vec2()
    }, mt)
end

setmetatable(window, {
    __call = function(t, settings)
        return window.new(settings)
    end
})

do 
    local methods = { }

    function methods:rect()
        return rect.new(self.pos, self.pos + self.size)
    end

    function methods:getRootWindow()
        return self.parent and self.parent:getRootWindow() or self
    end

    mt.__index = methods
end

return window