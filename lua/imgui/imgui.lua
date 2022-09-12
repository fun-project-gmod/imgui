local vec2 = grequire "imgui.vec2"
local rect = grequire "imgui.rect"
local window = grequire "imgui.window"

---@alias imcolor integer[]

---@class imcontext
---@field windows table<string, imwindow>
---@field pendingWindows imwindow[]
---@field frameWindows imwindow[]
---@field currentWindow imwindow?

---@class imgui
---@field context imcontext

local imgui = glue.load { 
    context = {
        windows = { },
        pendingWindows = { },
        frameWindows = { }
    }
}

do
    local internal = { }

    function internal.setCursor(pos)
        imgui.context.currentWindow.cursor = pos
    end

    function internal.updateFurthestPoint(pos)
        local window = imgui.context.currentWindow

        if pos.x > window.furthestPoint.x then
            window.furthestPoint.x = pos.x
        end

        if pos.y > window.furthestPoint.y then
            window.furthestPoint.y = pos.y
        end
    end

    function internal.advanceCursor(off, padding)
        local window = imgui.context.currentWindow
        window.cursor[1] = window.cursor[1] + padding[1]
        window.previousCursor:set(window.cursor)
        window.previousCursorMove = off
        internal.updateFurthestPoint(window.previousCursor + off)
        window.cursor[1] = window.pos[1] + padding[1]
        window.cursor[2] = window.cursor[2] + off[2] + padding[2]
        internal.updateFurthestPoint(window.cursor)
    end

    function internal.getTime()
        return SysTime()
    end

    function internal.getTick()
        return FrameNumber()
    end

    ---@param size vec2
    ---@return boolean clicked, boolean pressed, boolean hovered
    function internal.clickable(size)
        local window = imgui.context.currentWindow
        local cp = window.cursor
        local clicked, pressed, hovered = imgui.io.clickable(rect.new(cp, cp + size))
        hovered = hovered and window:rect():contains(imgui.io.mousePos())
        pressed = pressed and internal.isWindowSelected(window)
        return clicked and pressed and hovered, pressed, hovered
    end

    function internal.render()
        local ctx = imgui.context

        local pending = ctx.pendingWindows
        table.sort(pending, function(w1, w2) return w1.zindex < w2.zindex end)
        ctx.selectedWindow = pending[#pending]

        for k,v in ipairs(pending) do
            ctx.currentWindow = v
            imgui.styles.push(v.style)
            imgui.styles.pushOverride(v.styleOverrides)
            v.style.window(v)
            xpcall(v.callback, ErrorNoHaltWithStack)
            imgui.styles.popOverride()
            imgui.styles.pop()
            v.style.windowEnd(v)

            pending[k] = nil
        end

        ctx.currentWindow = nil
        ctx.frameWindows = { }
    end

    function internal.setTopWindow(window)
        local bzindex
        for k,v in pairs(imgui.context.windows) do 
            if not bzindex or bzindex < v.zindex then 
                bzindex = v.zindex
            end
        end

        window.zindex = (bzindex or 0) + 1
        imgui.context.selectedWindow = window
    end

    function internal.isWindowSelected(window)
        return imgui.context.selectedWindow == window:getRootWindow()
    end

    function internal.elementStorage(name)
        local elems = imgui.context.currentWindow.elements

        if not elems[name] then elems[name] = { } end
        return elems[name]
    end

    imgui.internal = internal
end

-- really should just make the get/pop/push shit a class and extend it
do
    local styles = {
        list = { },
        overrides = { }
    }

    function styles.setDefault(style)
        styles.default = style
    end

    function styles.get()
        local list = styles.list
        return list[#list] or styles.default 
    end

    function styles.push(style)
        table.insert(styles.list, style)
    end

    function styles.pop()
        table.remove(styles.list)
    end

    function styles.inherit(style)
        style = style or styles.default
        return setmetatable(
            {
                settings = styles.default.settings -- ugh i really need to improve this system but i dont have the time to
            },
            { __index = style }
        )
    end

    function styles.pushOverride(override)
        local style = styles.default
        local restore = { }

        for k,v in pairs(override) do 
            restore[k] = style.settings[k]
            style.settings[k] = v
        end

        table.insert(styles.overrides, restore)
    end

    function styles.popOverride()
        local style = styles.get()
        local restore = table.remove(styles.overrides)

        for k, v in pairs(restore) do
            style.settings[k] = v
        end
    end

    function styles.getOverrides()
        local style = styles.default
        local ovlist = styles.overrides
        local overrides = { }
        
        -- i realized that order does not matter but now im too lazy, sry
        for i = #ovlist, 1, -1 do 
            for k,v in pairs(ovlist[i]) do
                overrides[k] = style.settings[k]
            end
        end

        return overrides
    end

    imgui.styles = styles
end

do
    -- note: possible optimisation here, you can cache the style and avoid the call
    -- that wont do much, though

    local wcount = 0
    ---@param windows table<string, imwindow>
    ---@param name string
    ---@param settings imuserwindowsettings?
    ---@return imwindow
    local function getWindow(windows, name, settings)
        if not windows[name] then
            wcount = wcount + 1
            windows[name] = window {
                size = settings and settings.size,
                pos = settings and (settings.pos or settings.startpos),
                settings = settings or { },
                name = name,

                zindex = settings and settings.zindex or wcount
            }
        end
        local window = windows[name]
        window.furthestPoint = vec2()
        if settings.pos then 
            window.pos = settings.pos
        end

        return window
    end

    --- create a window, supposed to be ran in the 'ImGui' hook
    ---@param name string
    ---@param callback fun()
    ---@param settings? imuserwindowsettings
    function imgui.window(name, callback, settings)
        local ctx = imgui.context

        local window = getWindow(ctx.windows, name, settings)
        -- hate that i need to cache that, there should be a better way but im lazy af
        window.style = imgui.styles.get()
        window.styleOverrides = imgui.styles.getOverrides()
        window.callback = callback

        table.insert(ctx.pendingWindows, window)
        table.insert(ctx.frameWindows, window)
    end

    function imgui.text(text, r, g, b, a)
        imgui.styles.get().text(text, r, g, b, a)
    end

    function imgui.button(text, disabled, callback)
        local clicked = imgui.styles.get().button(text, imgui.fonts.get(), not disabled)

        if clicked and callback then 
            callback(clicked)
        end

        return clicked
    end

    ---@param name string
    ---@param value number
    ---@param min number
    ---@param max number
    ---@param interval number? @ = 0.01, interval between values
    ---@param format number? @ = "%.2f"
    ---@param callback fun(value: number)? @on change callback
    function imgui.slider(name, value, min, max, interval, format, callback)
        local newvalue = imgui.styles.get().slider(name, value, min, max, interval or 0.01, format or "%.2f")

        if callback and newvalue ~= value then
            callback(newvalue)
        end

        return newvalue
    end

    function imgui.sameLine()
        local window = imgui.context.currentWindow

---@diagnostic disable-next-line: assign-type-mismatch
        window.cursor = window.previousCursor + vec2(window.previousCursorMove[1], 0)
    end

    ---@param name string
    ---@param settings imuserwindowsettings
    function imgui.beginChild(name, settings)
        local ctx = imgui.context
        local parentWindow = ctx.currentWindow
        settings.pos = settings.pos or parentWindow.cursor
        local window = getWindow(parentWindow.windows, name, settings)
        window.parent = parentWindow
        window.pos:set(settings.pos)

        imgui.styles.get().childWindow(window)
    end

    function imgui.endChild()
        imgui.styles.get().childWindowEnd(imgui.context.currentWindow)
    end

    ---@param name string
    ---@param text string
    ---@param disabled boolean
    ---@param callback? fun(newtext: string):string @on change callback, return a new string to replace the text
    function imgui.inputText(name, text, disabled, callback)
        local newtext = imgui.styles.get().inputText(name, text, not disabled)

        if callback and newtext ~= text then 
            newtext = callback(newtext) or newtext
        end

        return newtext
    end

    ---@param name string
    ---@param value boolean
    ---@param disabled? boolean
    ---@param callback? fun(value: boolean)
    function imgui.checkBox(name, value, disabled, callback)
        local nv = imgui.styles.get().checkBox(name, value, not disabled)

        if callback and nv ~= value then 
            callback(nv)
        end

        return nv
    end

    function imgui.image(material, size, r, g, b, a, rotation)
        imgui.styles.get().image(material, size, r or 255, g or 255, b or 255, a or 255, rotation or 0)
    end

    function imgui.spacing(size)
        imgui.internal.advanceCursor(size, vec2())
    end
end

imgui.draw = grequire "imgui.draw"
imgui.fonts = grequire "imgui.fonts"
imgui.io = grequire "imgui.io"

return imgui