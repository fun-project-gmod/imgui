local vec2 = grequire "imgui.vec2"

---@class imfont
---@field init fun(self:imfont, data:table)
---@field getId fun(self:imfont):string
---@field apply fun(self:imfont)
---@field size fun(self:imfont, text:string?):vec2

local fonts = {
    list = { }
}

function fonts.push(font)
    table.insert(fonts.list, font)
end

function fonts.pop()
    table.remove(fonts.list)
end

---@return imfont
function fonts.get()
    local list = fonts.list
    return list[#list] or fonts.default
end

function fonts.setDefault(font)
    fonts.default = font
end

local mt = { }
function fonts.new(params)
    return setmetatable({ }, mt):init(params)
end

do 
    local index = { }

    local function generateId(data)
        local id = ""

        for k,v in SortedPairs(data) do 
            id = id .. tostring(v)
        end

        return ("IMGUIFONT_%08X"):format(util.CRC(id))
    end

    function index:init(data)
        self.data = data
        self.id = generateId(data)
        surface.CreateFont(self.id, data)
        
        return self
    end

    function index:getId()
        return self.id
    end

    function index:apply()
        surface.SetFont(self:getId())
    end

    function index:size(text)
        self:apply()
        return vec2.new(surface.GetTextSize(text or " "))
    end

    mt.__index = index
end

return fonts