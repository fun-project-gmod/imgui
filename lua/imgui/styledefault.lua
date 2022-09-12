local imgui = grequire "imgui.imgui"
local vec2 = grequire "imgui.vec2"
local rect = grequire "imgui.rect" 
local drag = grequire "imgui.drag"
local scale = grequire "imgui.scaling"
scale.setBaseResolution(1920, 1080)
    .setTargetResolution(ScrW(), ScrH())

local style = { }
local draw = imgui.draw

local settings = {
    windowTitleBarOffset = scale(4, 2),
    windowTitleBarColor = { 41, 74, 122, 255 },
    windowNameColor = { 255, 255, 255, 255 },

    baseWindowOffset = scale(4, 4),
    windowBackgroundColor = { 17, 17, 17, 255 },

    textColor = { 255, 255, 255, 255 },

    padding = scale(4, 4),

    buttonPadding = scale(2, 2),
    buttonColor = { 41, 74, 122, 255 },
    buttonDisabledColor = { 20, 37, 61, 255 },
    buttonHoveredColor = { 64, 131, 203, 255 },
    buttonPressedColor = { 32, 50, 77, 255 },
    buttonTextColor = { 255, 255, 255, 255 },

    sliderMariginRight = 8,
    sliderPaddingY = 2,
    sliderMinSlideSizeX = 10,
    sliderSlidePaddingY = 2,

    scrollSizeX = 4,
    scrollMinSizeY = 16,

    scrollSensitivity = 10,

    childWindowBackgroundColor = { 27, 27, 27, 255 },

    textInputPadding = scale(2, 0),
    textInputMariginRight = 8,

    checkBoxSize = scale(12, 12), -- outer part is defined by buttonPadding
    checkBoxInnerColor = { 66, 150, 250, 255 }
}
style.settings = settings

function style.text(text, r, g, b, a)
    local ctx = imgui.context

    r = r or settings.textColor[1]
    g = g or settings.textColor[2]
    b = b or settings.textColor[3]
    a = a or settings.textColor[4]

    local font = imgui.fonts.get()
    draw.text(ctx.currentWindow.cursor, font, text, r, g, b, a)
    imgui.internal.advanceCursor(font:size(text), settings.padding)
end

-- potentially slow code fragment
local function isPositionInsideAnyWindow(pos, except)
    for k, v in ipairs(imgui.context.frameWindows) do
        if v ~= except and v.zindex > except.zindex and v:rect():contains(pos) then
            return true
        end
    end

    return false
end

local function windowSelectionCheck(window)
    local clicked = imgui.io.clickable(window:rect())
    if clicked then
        if isPositionInsideAnyWindow(imgui.io.mousePos(), window) then 
            return
        end

        if not window.settings.zindex then
            imgui.internal.setTopWindow(window)
        end
    end
end

local function enterWindow(window, topsizey)
    local basepos = window.pos

    window.basePoint:setxy(basepos.x, basepos.y + topsizey)
    window.cursor:set(window.basePoint):subxy(0, window.scrolly)
    window.basePointNoScroll:set(window.cursor)
    window.cursor:add(settings.baseWindowOffset)

    window.drawn = true
end

---@param window imwindow
local function shouldScrollWindow(window)
    local rootWindow = window:getRootWindow()
    if window:rect():contains(imgui.io.mousePos()) 
        and (imgui.internal.isWindowSelected(window) or not isPositionInsideAnyWindow(imgui.io.mousePos(), rootWindow)) then
        return true
    end

    return false
end

---@param window imwindow
local function shouldScrollChild(window)
    for k,v in pairs(window.windows) do 
        if shouldScrollWindow(v) then 
            local scroll = imgui.io.scroll
            
            if scroll > 0 then 
                return v.scrolly > 0
            elseif scroll < 0 then
                return v.scrolly < (v.furthestPoint.y - v.basePointNoScroll.y) - v.contentSize.y
            end
        end
    end

    return false
end

---@param window imwindow
local function leaveWindow(window)
    local locfurthest = window.furthestPoint - window.basePointNoScroll
    local furthesty = locfurthest.y
    local contentSize = window.contentSize
    if furthesty > contentSize.y and not window.settings.noScroll then
        local scrollsizey = math.max(contentSize.y / furthesty * contentSize.y, settings.scrollMinSizeY)
        local scrolloff = window.scrolly / furthesty * contentSize.y

        local scrollsize = vec2(settings.scrollSizeX, scrollsizey)
        local scrollpos = window.basePoint + vec2(contentSize.x - scrollsize.x, scrolloff)

        if imgui.internal.isWindowSelected(window) then
            window.scrollDrag = drag.update(window.scrollDrag) or drag.begin(rect(scrollpos, scrollpos + scrollsize), window.basePoint)
            if window.scrollDrag then
                window.scrolly = furthesty * (window.scrollDrag.posRelative.y / contentSize.y)
            end
        end

        if shouldScrollWindow(window) and not shouldScrollChild(window) then
            window.scrolly = window.scrolly - imgui.io.scroll * settings.scrollSensitivity
        end

        imgui.draw.rect(scrollpos, scrollsize, 255, 255, 255, 127)
    end
    window.scrolly = math.max(0, math.min(window.scrolly, furthesty - window.contentSize.y))

    if window.autoSize then
        window.size:set(locfurthest)
        window.size:addxy(0, window.topSize.y)
    end

    for k,v in pairs(window.windows) do 
        if not v.drawn then 
            window.windows[k] = nil
        end
        v.drawn = false
    end
end

---@param window imwindow
function style.window(window)
    local font = imgui.fonts.get()

    windowSelectionCheck(window)

    local topsizey = 0
    local topsize = vec2.new()

    if not window.settings.noDecoration then 
        topsizey = font:size(window.name).y + settings.windowTitleBarOffset.y * 2

        topsize.x = window.size.x
        topsize.y = topsizey
    end

    window.topSize = topsize
    window.contentSize:set(window.size):subxy(0, topsizey)

    if window.settings.noDrag and imgui.internal.isWindowSelected(window) then
        window.drag = drag.update(window.drag) or drag.begin(rect(window.pos, window.pos + topsize))
        if window.drag then
            window.pos = window.drag.pos
        end
    end

    draw.clip.clear()
    draw.clip.enter()
    draw.clip.enable()
    draw.clip.record()

    local basepos = window.pos

    --draw.roundedRect(basepos, window.size, 4, 17, 17, 17, 255, true, true, true, true)
    draw.rect(basepos, window.size, 255, 255, 255, 1)

    draw.clip.apply()

    if not window.settings.noDecoration then 
        draw.rect(basepos, topsize, unpack(settings.windowTitleBarColor))
        draw.text(basepos + settings.windowTitleBarOffset, font, window.name, settings.windowNameColor)
    end

    draw.clip.enter()
    draw.clip.record()
    draw.rect(basepos + vec2(0, topsizey), window.size, unpack(settings.windowBackgroundColor))

    enterWindow(window, topsizey)

    draw.clip.apply()
end

---@param window imwindow
function style.windowEnd(window)
    leaveWindow(window)

    draw.clip.disable()
    draw.clip.leave()
    draw.clip.leave()
end

local function buttonBehavior(size, enabled)
    local ctx = imgui.context
    local rs = size + settings.buttonPadding * 2

    local clicked, pressed, hovered = imgui.internal.clickable(rs)

    local color = settings.buttonColor
    if enabled then
        if hovered then
            color = settings.buttonHoveredColor
        end

        if pressed then
            color = settings.buttonPressedColor
        end
    else
        color = settings.buttonDisabledColor
    end

    local pos = ctx.currentWindow.cursor + settings.buttonPadding
    draw.rect(ctx.currentWindow.cursor, rs, unpack(color))

    return clicked and enabled, pos, rs
end

function style.button(text, font, enabled)
    local ts = font:size(text)
    local clicked, pos, size = buttonBehavior(ts, enabled)
    draw.text(pos, font, text, unpack(settings.buttonTextColor))
    imgui.internal.advanceCursor(size, settings.padding)

    return clicked
end

function style.slider(name, value, min, max, interval, format)
    local window = imgui.context.currentWindow
    local font = imgui.fonts.get()

    imgui.text(name)
    imgui.sameLine()

    local basepos = window.cursor

    local size = vec2(
        window.contentSize.x - (basepos.x - window.pos.x) - settings.sliderMariginRight, 
        settings.sliderPaddingY * 2 + font:size().y
    )

    imgui.draw.rect(basepos, size, 32, 50, 77)

    local slidesizex = math.max(settings.sliderMinSlideSizeX, size.x / ((max - min) / interval))
    local slidesize = vec2(slidesizex, size.y - settings.sliderSlidePaddingY)
    local stor = imgui.internal.elementStorage(name)

    stor.drag = drag.update(stor.drag) or drag.begin(rect(basepos, basepos + size))

    local color
    if stor.drag then 
        color = { 61, 133, 224, 255 }
        
        local x = imgui.io.mousePos().x - basepos.x
        x = math.max(0, math.min(x, size.x))

        value = min + (max - min) * x / size.x
        value = min + math.ceil(((value - min) / interval) - 0.5) * interval
    else
        local clicked, pressed, hovered = imgui.internal.clickable(size)

        if hovered then 
            color = settings.buttonHoveredColor
        else
            color = settings.buttonColor
        end
    end

    local progress = (value - min) / (max - min)
    local slidepos = basepos +
        vec2(
            math.max(0, math.min(progress * size.x - slidesizex / 2, size.x - slidesizex)),
            settings.sliderSlidePaddingY
        )

    imgui.draw.rect(slidepos, slidesize, unpack(color))

    local text = format:format(value)
    local ts = font:size(text)
    imgui.draw.text(basepos + size / 2 - ts / 2, font, text, 255, 255, 255)

    imgui.internal.advanceCursor(size, settings.padding)

    return value
end

---@param window imwindow
function style.childWindow(window)
    local ctx = imgui.context

    window.contentSize:set(window.size)

    draw.clip.enter()
    draw.clip.record()

    ctx.currentWindow = window
    draw.rect(window.pos, window.contentSize, unpack(settings.childWindowBackgroundColor))

    draw.clip.apply()

    enterWindow(window, 0)
end

---@param window imwindow
function style.childWindowEnd(window)
    leaveWindow(window)

    draw.clip.leave()
    imgui.context.currentWindow = window.parent
    imgui.internal.advanceCursor(window.contentSize, settings.padding)
end

local function updateSelection(state)
    if imgui.io.getKeyState(KEY_LSHIFT).pressed then
        state.es.selection = state.es.selection or state.es.cursor
    else
        state.es.selection = nil
    end
end

local function getSelectionBoundaries(es)
    local min, max = es.cursor, es.selection
    if min == max or max == nil then 
        return min
    end

    if min > max then 
        return max, min
    end

    return min, max
end

local function cutSelectedText(state)
    local from, to = getSelectionBoundaries(state.es)
    if to then
        state.es.cursor = from
        state.es.selection = nil
        return utf8.sub(state.text, 1, from) .. utf8.sub(state.text, to + 1)
    end
end

local keyboardActions = {
    [KEY_BACKSPACE] = function(state)
        local cut = cutSelectedText(state)
        if cut then return cut end

        state.cursorText[1] = utf8.sub(state.cursorText[1], 1, -2)
        state.es.cursor = math.max(0, state.es.cursor - 1)
    end,
    [KEY_DELETE] = function(state)
        local cut = cutSelectedText(state)
        if cut then return cut end

        state.cursorText[2] = utf8.sub(state.cursorText[2], 2)
    end,
    [KEY_DOWN] = function (state)
        updateSelection(state)
        state.es.cursor = utf8.len(state.text)
    end,
    [KEY_UP] = function (state)
        updateSelection(state)
        state.es.cursor = 0
    end,
    [KEY_LEFT] = function(state)
        local from, to = getSelectionBoundaries(state.es)
        updateSelection(state)
        local pos = state.es.cursor - 1
        if not state.es.selection and to then 
            pos = from
        end
        state.es.cursor = math.max(0, pos)
    end,
    [KEY_RIGHT] = function(state)
        local from, to = getSelectionBoundaries(state.es)
        updateSelection(state)
        local pos = state.es.cursor + 1
        if not state.es.selection and to then
            pos = to
        end
        state.es.cursor = math.min(pos, utf8.len(state.text))
    end,
    [KEY_A] = function(state)
        if imgui.io.getKeyState(KEY_LCONTROL).pressed then
            state.es.cursor = 0
            state.es.selection = utf8.len(state.text)
        end
    end,
    [KEY_C] = function(state)
        if imgui.io.getKeyState(KEY_LCONTROL).pressed then
            local from, to = getSelectionBoundaries(state.es)
            local text = utf8.sub(state.text, from + 1, to)
            SetClipboardText(text)
        end
    end,
}

local function createInputState(es, text)
    return {
        es = es,
        cursorText = { utf8.sub(text, 1, es.cursor), utf8.sub(text, es.cursor + 1) },
        text = text
    }
end

function style.inputText(name, text, enabled)
    local window = imgui.context.currentWindow
    local font = imgui.fonts.get()

    imgui.text(name)
    imgui.sameLine()

    local basepos = window.cursor

    local size = vec2(
        window.contentSize.x - (basepos.x - window.pos.x) - settings.textInputMariginRight,
        settings.textInputPadding.y * 2 + font:size().y
    )

    local es = imgui.internal.elementStorage(name)
    local pos = basepos + settings.textInputPadding
    imgui.draw.clip.enter()
    imgui.draw.clip.record()
    imgui.draw.rect(basepos, size, 32, 50, 77, enabled and 255 or 127)
    imgui.draw.clip.apply()
    imgui.draw.text(pos, font, text, 255, 255, 255, 255)
    
    es.selected = es.selected and enabled
    if es.selected then
        local from, to = getSelectionBoundaries(es)
        if to then
            local s1 = font:size(utf8.sub(text, 1, from))
            local s2 = font:size(utf8.sub(text, 1, to))

            local sizex = s2.x - s1.x

            imgui.draw.rect(vec2(basepos.x + s1.x, basepos.y), vec2(sizex, s2.y), 255, 255, 255, 40)
        else
            local ts = font:size(utf8.sub(text, 1, from))
            local posx = basepos.x + ts.x + 2

            imgui.draw.rect(vec2(posx, basepos.y), vec2(1, ts.y), 255, 255, 255, 255)
        end
    end

    imgui.draw.clip.leave()

    local clicked = enabled and imgui.internal.clickable(size)
    if clicked then 
        es.selected = true

        local xoff = imgui.io.mouse[MOUSE_LEFT].clickpos.x - basepos.x - settings.textInputPadding.x
        local cpos = 1
        for i = 1, utf8.len(text) do 
            if font:size(utf8.sub(text, 1, i)).x <= xoff then 
                cpos = i
            else
                break
            end
        end

        es.cursor = cpos
        es.selection = nil
    elseif imgui.io.mouse[MOUSE_LEFT].clicked then
        es.selected = false
    end

    imgui.internal.advanceCursor(size, settings.padding)

    if es.selected then 
        local state = createInputState(es, text)

        local input = imgui.io.keyboardInput
        if #input ~= 0 then
            local cut = cutSelectedText(state)
            if cut then
                state = createInputState(es, cut)
            end
            state.cursorText[1] = state.cursorText[1] .. input
            es.cursor = es.cursor + utf8.len(input)
            text = state.cursorText[1] .. state.cursorText[2]
        end

        -- you need to recreate the state every time you modify its contents
        -- inefficient but i dont care as long as its kind of dev-friendly
        state = createInputState(es, text)

        for k,v in ipairs(imgui.io.keysTyped) do
            local handler = keyboardActions[v.key]
            if handler then 
                local t = handler(state)
                if t then 
                    text = t
                else
                    text = state.cursorText[1] .. state.cursorText[2]
                end

                state = createInputState(es, text)
            end
        end

        text = state.cursorText[1] .. state.cursorText[2]
        if es.selectionTo then
            es.selectionTo = math.min(utf8.len(text), es.selectionTo)
            if es.selectionTo == 0 then
                es.selectionTo = nil
                es.selectionFrom = nil
            end
        end
        return text
    end

    return text
end

-- potential bug: if the font size is too big it can overflow
function style.checkBox(name, value, enabled)
    local clicked, pos, csize = buttonBehavior(settings.checkBoxSize, enabled)
    if clicked then
        value = not value
    end

    if value then 
        imgui.draw.rect(pos, settings.checkBoxSize, unpack(settings.checkBoxInnerColor))
    end

    local font = imgui.fonts.get()
    local ts = font:size(name)
    local size = vec2(csize.x + settings.padding.x + ts.x, csize.y)
    local pos = imgui.context.currentWindow.cursor + vec2(csize.x + settings.padding.x, csize.y / 2 - ts.y / 2)
    imgui.draw.text(pos, font, name, 255, 255, 255, 255)

    imgui.internal.advanceCursor(size, settings.padding)

    return value
end

function style.image(material, size, r, g, b, a, rotation)
    draw.image(imgui.context.currentWindow.cursor, material, size, r, g, b, a, rotation)
    imgui.internal.advanceCursor(size, settings.padding)
end

imgui.styles.setDefault(style)