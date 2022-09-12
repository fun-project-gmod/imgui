local imgui = grequire "imgui.imgui"
local vec2 = grequire "imgui.vec2"

imgui.fonts.setDefault(
    imgui.fonts.new {
        font = "Tahoma",
        size = 12
    }
)

grequire "imgui.styledefault"

hook.Add("HUDPaint", "IMGUI-RENDER", function()
    hook.Call("ImGui")
    imgui.internal.render()
end)
