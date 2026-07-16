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
    function Panel:NewSlider(id, text, low, high, step)
        local name = self:GetName() .. 'Input' .. id

        local f = CreateFrame('Frame', name, self)
        f:SetSize(160, 40)
        
        local label = f:CreateFontString(name .. 'Text', 'ARTWORK', 'GameFontNormal')
        label:SetPoint('TOPLEFT', f, 'TOPLEFT', 4, 0)
        label:SetText(text)

        local input = CreateFrame('EditBox', name .. 'Box', f, 'InputBoxTemplate')
        input:SetSize(40, 20)
        input:SetPoint('TOPLEFT', label, 'BOTTOMLEFT', 4, -4)
        input:SetAutoFocus(false)
        input:SetNumeric(false) 

        f.input = input
        f.minVal = low
        f.maxVal = high

        local valString = f:CreateFontString(nil, 'BACKGROUND', 'GameFontHighlightSmall')
        valString:SetPoint('LEFT', input, 'RIGHT', 8, 0)
        f.valText = valString

        f.SetMinMaxValues = function(selfFrame, minV, maxV) 
            selfFrame.minVal = minV 
            selfFrame.maxVal = maxV 
        end
        
        f.SetValue = function(selfFrame, val) 
            local formatted = string.format("%g", val or 0)
            selfFrame.input:SetText(formatted) 
        end
        
        f.GetValue = function(selfFrame) 
            return tonumber(selfFrame.input:GetText()) or 0 
        end

        input:SetScript('OnEnter', function(selfBox)
            GameTooltip:SetOwner(selfBox, 'ANCHOR_RIGHT')
            GameTooltip:SetText("Press Enter to save value", 1, 1, 1)
            GameTooltip:Show()
        end)
        input:SetScript('OnLeave', function() GameTooltip:Hide() end)

        local function SaveValue(selfBox)
            local parent = selfBox:GetParent()
            local val = tonumber(selfBox:GetText()) or parent.minVal or 0
            
            if parent.minVal and val < parent.minVal then val = parent.minVal end
            if parent.maxVal and val > parent.maxVal then val = parent.maxVal end
            
            local formatted = string.format("%g", val)
            selfBox:SetText(formatted)
            selfBox:ClearFocus()
        end

        input:SetScript('OnEnterPressed', SaveValue)
        input:SetScript('OnEscapePressed', function(selfBox) selfBox:ClearFocus() end)

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