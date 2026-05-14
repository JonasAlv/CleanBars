local Panel = CleanBars:CreateClass('Frame')
local _G = getfenv(0)
local min = math.min
local max = math.max

function Panel:New(name, title, subtitle, parent)
    local f = self:Bind(CreateFrame('Frame', name, UIParent))
    f.name = title
    f.parent = parent
    
    local text = f:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
    text:SetPoint('TOPLEFT', 16, -16)
    text:SetText(title)

    local subtext = f:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightSmall')
    subtext:SetHeight(32)
    subtext:SetPoint('TOPLEFT', text, 'BOTTOMLEFT', 0, -8)
    subtext:SetPoint('RIGHT', f, -32, 0)
    subtext:SetNonSpaceWrap(true)
    subtext:SetJustifyH('LEFT')
    subtext:SetJustifyV('TOP')
    subtext:SetText(subtitle)
    
    InterfaceOptions_AddCategory(f)

    return f
end

do
    local function Slider_OnMouseWheel(self, arg1)
        local step = self:GetValueStep() * arg1
        local value = self:GetValue()
        local minVal, maxVal = self:GetMinMaxValues()

        if step > 0 then
            self:SetValue(min(value+step, maxVal))
        else
            self:SetValue(max(value+step, minVal))
        end
    end

    function Panel:NewSlider(text, low, high, step)
        local name = self:GetName() .. text
        local f = CreateFrame('Slider', name, self, 'OptionsSliderTemplate')
        f:SetScript('OnMouseWheel', Slider_OnMouseWheel)
        f:SetMinMaxValues(low, high)
        f:SetValueStep(step)
        f:EnableMouseWheel(true)

        _G[name .. 'Text']:SetText(text)
        _G[name .. 'Low']:SetText('')
        _G[name .. 'High']:SetText('')

        local text = f:CreateFontString(nil, 'BACKGROUND', 'GameFontHighlightSmall')
        text:SetPoint('LEFT', f, 'RIGHT', 7, 0)
        f.valText = text

        return f
    end
end

function Panel:NewCheckButton(name)
    local b = CreateFrame('CheckButton', self:GetName() .. name, self, 'InterfaceOptionsCheckButtonTemplate')
    _G[b:GetName() .. 'Text']:SetText(name)

    return b
end

function Panel:NewSmallCheckButton(name)
    local b = CreateFrame('CheckButton', self:GetName() .. name, self, 'InterfaceOptionsSmallCheckButtonTemplate')
    _G[b:GetName() .. 'Text']:SetText(name)

    return b
end

function Panel:NewSecureCheckButton(name, template)
    local b = CreateFrame('CheckButton', self:GetName() .. name, self, 'InterfaceOptionsCheckButtonTemplate,' .. template)
    _G[b:GetName() .. 'Text']:SetText(name)

    return b
end

function Panel:NewDropdown(name)
    local f = CreateFrame('Frame', self:GetName() .. name, self, 'UIDropDownMenuTemplate')

    local text = f:CreateFontString(nil, 'BACKGROUND', 'GameFontNormalSmall')
    text:SetPoint('BOTTOMLEFT', f, 'TOPLEFT', 21, 0)
    text:SetText(name)

    return f
end

function Panel:NewButton(name, width, height)
    local b = CreateFrame('Button', self:GetName() .. name, self, 'UIPanelButtonTemplate')
    b:SetText(name)
    b:SetWidth(width)
    b:SetHeight(height or width)

    return b
end

do
    local name, desc = select(2, GetAddOnInfo('CleanBars'))
    CleanBars.Options = Panel:New('CleanBarsOptions', name, desc, nil)
end