local imgui = grequire "imgui.imgui"
local vec2 = grequire "imgui.vec2"

local io = { 
    mousepos = vec2.new(),
    mouse = { 
        [MOUSE_LEFT] = { },
        [MOUSE_RIGHT] = { },
        [MOUSE_MIDDLE] = { },
        [MOUSE_4] = { },
        [MOUSE_5] = { },
        [MOUSE_WHEEL_UP] = { },
        [MOUSE_WHEEL_DOWN] = { },
    },
    acceptingMouse = false,
    scroll = 0,
    lastScroll = 0,
    
    keyboardPanel = nil,
    keyboardListener = nil,
    keyboardInput = "",
    keys = { },
    keysTypedBeforeUpdate = { },
    keysTyped = { }
}

function io.acceptMouseInput(state)
    io.acceptingMouse = state
    gui.EnableScreenClicker(state)
end
io.acceptMouseInput(true)

function io.getKeyState(key)
    if not io.keys[key] then 
        io.keys[key] = { }
    end

    return io.keys[key]
end

function io.isKeyTyped(key)
    return io.keys[key] and io.keys[key].typedTick == imgui.internal.getTick()
end

function io.acceptKeyboardInput(state)
    if state then 
        io.keyboardPanel = vgui.Create("EditablePanel")
        io.keyboardPanel:MakePopup()
        io.keyboardPanel:SetPaintedManually(true)
        io.keyboardListener = vgui.Create("TextEntry", io.keyboardPanel)
        io.keyboardListener:RequestFocus()
        io.keyboardListener:SetAllowNonAsciiCharacters(true)
        function io.keyboardListener:OnKeyCodeTyped(key) -- not doing .typed to avoid iterating all keys every frame, better do .typedTick == currentTick
            local ks = io.getKeyState(key)
            ks.typedTick = imgui.internal.getTick()
            ks.typedTime = imgui.internal.getTime()

            if not ks.pressed then
                ks.pressed = true
                ks.pressedTick = imgui.internal.getTick()
                ks.pressedTime = imgui.internal.getTime()
            end

            table.insert(io.keysTypedBeforeUpdate, { key = key, state = ks })
        end

        function io.keyboardListener:OnKeyCodeReleased(key)
            local ks = io.getKeyState(key)
            ks.pressed = false
            ks.releasedTick = imgui.internal.getTick()
            ks.releasedTime = imgui.internal.getTime()
        end
    else
        if io.keyboardListener then
            io.keyboardPanel:Remove()
            io.keyboardPanel = nil
            io.keyboardListener:Remove()
            io.keyboardListener = nil
        end
    end
end
io.acceptKeyboardInput(true)

io.clicked = { }
function io.onMousePress(button, pos)
    local info = io.mouse[button]
    
    info.pressed = true
    info.clicked = true
    info.justreleased = false
    info.clicktime = imgui.internal.getTime()
    info.clicktick = imgui.internal.getTick()
    info.clickpos = pos
end

function io.onMouseRelease(button, pos)
    local info = io.mouse[button]
    if not info.pressed then 
        io.onMousePress(button, pos)
    end
    info.shouldrelease = info.clicktick + 1
end

function io.update()
    if io.keyboardListener then 
        io.keyboardListener:RequestFocus()

        io.keyboardInput = io.keyboardListener:GetText()
        io.keyboardListener:SetText("")
    else
        io.keyboardInput = ""
    end
    io.keysTyped = io.keysTypedBeforeUpdate
    io.keysTypedBeforeUpdate = { }

    io.mousepos = io.mousePos()
    local scroll = input.GetAnalogValue(ANALOG_MOUSE_WHEEL)
    io.scroll = scroll - io.lastScroll
    io.lastScroll = scroll

    for k,info in pairs(io.mouse) do
        info.clicked = info.clicktick == imgui.internal.getTick()

        if info.shouldrelease and info.shouldrelease < imgui.internal.getTick() then
            info.shouldrelease = false
            info.pressed = false
            info.clicked = false
            info.justreleased = true
            info.releasetime = imgui.internal.getTick()
            info.releasetick = tick
            info.releasepos = pos
        end

        info.justreleased = info.releasetick == imgui.internal.getTick()
    end
end

function io.mousePos()
    return vec2.new(input.GetCursorPos())
end

---@param rect rect
---@param button number? @ = MOUSE_LEFT
---@return boolean clicked, boolean pressed, boolean hovered
function io.clickable(rect, button)
    if not io.acceptingMouse then return false, false, false end

    button = button or MOUSE_LEFT

    local hovered = rect:contains(io.mousepos)
    local pressed = io.mouse[button].pressed and rect:contains(io.mouse[button].clickpos)
    local clicked = pressed and io.mouse[button].clicked

    return clicked, pressed, hovered
end

hook.Add("RenderScene", "IMGUI-IO", io.update)

hook.Add("GUIMousePressed", "IMGUI-IO", function(mouse)
    if not io.acceptingMouse then return end
    io.onMousePress(mouse, io.mousePos())
end)

hook.Add("GUIMouseReleased", "IMGUI-IO", function(mouse)
    if not io.acceptingMouse then return end
    io.onMouseRelease(mouse, io.mousePos())
end)

concommand.Add("iminputm", function()
    io.acceptMouseInput(not io.acceptingMouse)
end)

concommand.Add("iminputk", function()
    io.acceptKeyboardInput(not io.keyboardListener)
end)

return io