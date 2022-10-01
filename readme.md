# IMGUI

Small 2D UI Library

# Requirements

grequire ???

# Small Documentation

- drag.lua <br/>
  - drag.begin(rect, base) <br/>
  - drag.update(dragging) <br/>
- draw.lua <br/>
  - drawing.rect(pos, size, r, g, b, a) <br/>
  - drawing.rectAbs(pos1, pos2, r, g, b, a) <br/>
  - drawing.filledCircle(pos, radius, seg, actualSeg, r, g, b, a) <br/>
  - drawing.roundedRect(pos, size, rounding, r, g, b, a, tl, tr, bl, br, detail) <br/>
  - drawing.text(pos, font, text, r, g, b, a) <br/>
  - drawing.image(pos, material, size, r, g, b, a, rotation) <br/>
  - drawing.clip.clear() <br/>
  - drawing.clip.enable() <br/>
  - drawing.clip.disable() <br/>
  - drawing.clip.record() <br/>
  - drawing.clip.apply() <br/>
  - drawing.clip.enter() <br/>
  - drawing.clip.leave() <br/>
- fonts.lua <br/>
  - fonts.push(font) <br/>
  - fonts.pop() <br/>
  - fonts.get() <br/>
  - fonts.setDefault(font) <br/>
  - fonts.new(font) <br/>
  - (meta)fonts.init(data) <br />
  - (meta)fonts.getId() <br />
  - (meta)fonts.apply() <br />
  - (meta)fonts.size(text) <br />
- imgui.lua <br/>
  - imgui.text(text, r, g, b, a) <br/>
  - imgui.button(text, disabled, callback) <br/>
  - imgui.slider(name, value, min, max, interval, format, callback) <br/>
  - imgui.sameLine() <br/>
  - imgui.beginChild(name, settings) <br/>
  - imgui.inputText(name, text, disabled, callback) <br/>
  - imgui.image(material, size, r, g, b, a, rotation) <br/>
  - imgui.spacing(size) <br/>
- io.lua <br/>
  - io.acceptMouseInput(state) <br/>
  - io.isKeyTyped(key) <br/>
  - io.acceptKeyboardInput(state)<br/>
  - io.onMousePress(button, pos) <br/>
  - io.onMouseRelease(button, pos) <br/>
  - io.mousePos() <br/>
  - io.clickable(rect, button) <br/>
  - concommand - iminputm <br/>
  - concommand - iminputk <br/>
- main.lua <br/>
- rect.lua <br/>
  - rect.new(p1, p2) <br/>
  - rect.copy(r) <br/>
  - (meta) rect.contains(pos) <br/>
  - (meta) rect.center() <br/>
- scaling.lua <br/>
  - scaling.setBaseResolution(w, h) <br/>
  - scaling.setTargetResolution(w, h) <br/>
  - scaling.scale(vec) <br/>
  - scaling.new(vec) <br/>
  - scaling.scaled(x, y) <br/>
  - (meta) scaling(x,y) <br />
- styledefault.lua <br/>
- vec2.lua <br/>
  - vec2.new(x, y) <br/>
  - vec2.copy(x, y) <br/>
  - (meta) vec2.set(vec) <br/>
  - (meta) vec2.setxy(x, y) <br/>
  - (meta) vec2.sub(v) <br/>
  - (meta) vec2.add(v) <br/>
  - (meta) vec2.addxy(x, y) <br/>
- window.lua <br/>
  - window.new(settings) <br/>
  - (meta) window.rect() <br/>
  - (meta) window.getRootWindow() <br/>
