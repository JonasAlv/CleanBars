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
            self:SetValue(min(value + step, maxVal))
        else
            self:SetValue(max(value + step, minVal))
        end
    end

    local function Slider_OnValueChanged(self, value)
        if self.valText then
            self.valText:SetText(value)
        end
    end

    function Panel:NewSlider(id, text, low, high, step)
        local name = self:GetName() .. 'Slider' .. id
        local f = CreateFrame('Slider', name, self, 'OptionsSliderTemplate')
        f:SetScript('OnMouseWheel', Slider_OnMouseWheel)
        f:SetScript('OnValueChanged', Slider_OnValueChanged)
        f:SetMinMaxValues(low, high)
        f:SetValueStep(step)
        f:EnableMouseWheel(true)

        _G[name .. 'Text']:SetText(text)
        _G[name .. 'Low']:SetText('')
        _G[name .. 'High']:SetText('')

        local valString = f:CreateFontString(nil, 'BACKGROUND', 'GameFontHighlightSmall')
        valString:SetPoint('LEFT', f, 'RIGHT', 7, 0)
        f.valText = valString

        local prev = self.lastControl
        if prev then
            f:SetPoint('TOPLEFT', prev, 'BOTTOMLEFT', 0, -24)
        else
            f:SetPoint('TOPLEFT', 16, -80)
        end
        self.lastControl = f

        return f
    end
end

function Panel:NewCheckButton(id, text)
    local b = CreateFrame('CheckButton', self:GetName() .. 'Check' .. id, self, 'InterfaceOptionsCheckButtonTemplate')
    _G[b:GetName() .. 'Text']:SetText(text)

    local prev = self.lastControl
    if prev then
        b:SetPoint('TOPLEFT', prev, 'BOTTOMLEFT', 0, -8)
    else
        b:SetPoint('TOPLEFT', 16, -80)
    end
    self.lastControl = b

    return b
end

function Panel:NewSmallCheckButton(id, text)
    local b = CreateFrame('CheckButton', self:GetName() .. 'CheckSmall' .. id, self, 'InterfaceOptionsSmallCheckButtonTemplate')
    _G[b:GetName() .. 'Text']:SetText(text)

    local prev = self.lastControl
    if prev then
        b:SetPoint('TOPLEFT', prev, 'BOTTOMLEFT', 0, -4)
    else
        b:SetPoint('TOPLEFT', 24, -80)
    end
    self.lastControl = b

    return b
end

function Panel:NewSecureCheckButton(id, text, template)
    local b = CreateFrame('CheckButton', self:GetName() .. 'SecureCheck' .. id, self, 'InterfaceOptionsCheckButtonTemplate,' .. template)
    _G[b:GetName() .. 'Text']:SetText(text)

    local prev = self.lastControl
    if prev then
        b:SetPoint('TOPLEFT', prev, 'BOTTOMLEFT', 0, -8)
    else
        b:SetPoint('TOPLEFT', 16, -80)
    end
    self.lastControl = b

    return b
end

function Panel:NewDropdown(id, text)
    local f = CreateFrame('Frame', self:GetName() .. 'Drop' .. id, self, 'UIDropDownMenuTemplate')

    local displayLabel = f:CreateFontString(nil, 'BACKGROUND', 'GameFontNormalSmall')
    displayLabel:SetPoint('BOTTOMLEFT', f, 'TOPLEFT', 21, 0)
    displayLabel:SetText(text)

    local prev = self.lastControl
    if prev then
        f:SetPoint('TOPLEFT', prev, 'BOTTOMLEFT', -14, -20)
    else
        f:SetPoint('TOPLEFT', 2, -100)
    end
    self.lastControl = f

    return f
end

function Panel:NewButton(text, width, height)
    local id = tostring(text):gsub('[^%w]', '')
    local b = CreateFrame('Button', self:GetName() .. 'Btn' .. id, self, 'UIPanelButtonTemplate')
    b:SetText(text)
    b:SetWidth(width)
    b:SetHeight(height or width)

    return b
end

do
    local name, desc = select(2, GetAddOnInfo('CleanBars'))
    CleanBars.Options = Panel:New('CleanBarsOptions', name, desc, nil)
end