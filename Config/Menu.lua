local Menu = CleanBars:CreateClass('Frame')
CleanBars.Menu = Menu

local L = ConfigLocale
local _G = getfenv(0)
local max = math.max
local min = math.min

Menu.bg = {
    bgFile = 'Interface\\DialogFrame\\UI-DialogBox-Background',
    edgeFile = 'Interface\\DialogFrame\\UI-DialogBox-Border',
    insets = {left = 11, right = 11, top = 12, bottom = 11},
    tile = true,
    tileSize = 32,
    edgeSize = 32,
}

Menu.extraWidth = 20
Menu.extraHeight = 44

function Menu:New(name)
    local f = self:Bind(CreateFrame('Frame', 'CleanBarsFrameMenu' .. name, UIParent))
    f.panels = {}

    f:SetBackdrop(self.bg)
    f:EnableMouse(true)
    f:SetToplevel(true)
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:SetFrameStrata('DIALOG')
    f:SetScript('OnMouseDown', self.StartMoving)
    f:SetScript('OnMouseUp', self.StopMovingOrSizing)

    f.text = f:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
    f.text:SetPoint('TOP', 0, -15)

    f.close = CreateFrame('Button', nil, f, 'UIPanelCloseButton')
    f.close:SetPoint('TOPRIGHT', -5, -5)

    return f
end

function Menu:SetOwner(owner)
    self.owner = owner
    for _, f in pairs(self.panels) do
        f.owner = owner
    end

    if tonumber(owner.id) then
        self.text:SetFormattedText(L.ActionBarSettings, owner.id)
    else
        self.text:SetFormattedText(L.BarSettings, tostring(owner.id):gsub('^%l', string.upper))
    end

    self:Anchor(owner)
    
    local selectedPanel = self.panels[self:GetSelectedPanel()]
    if selectedPanel and selectedPanel.Refresh then
        selectedPanel:Refresh()
    end
end

function Menu:Anchor(f)
    local ratio = UIParent:GetScale() / f:GetEffectiveScale()
    local x = f:GetLeft() / ratio
    local y = f:GetTop() / ratio

    self:ClearAllPoints()
    self:SetPoint('TOPRIGHT', UIParent, 'BOTTOMLEFT', x, y)
end

function Menu:ShowPanel(name)
    for i, panel in pairs(self.panels) do
        if panel.name == name then
            if self.dropdown then
                UIDropDownMenu_SetSelectedValue(self.dropdown, i)
            end
            panel:Show()
            if panel.Refresh then panel:Refresh() end
            self:SetWidth(max(220, panel.width + self.extraWidth))
            self:SetHeight(max(60, panel.height + self.extraHeight))
        else
            panel:Hide()
        end
    end
end

function Menu:GetSelectedPanel()
    for i, panel in pairs(self.panels) do
        if panel:IsShown() then
            return i
        end
    end
    return 1
end

function Menu:NewPanel(name)
    local panel = self.Panel:New(name, self)
    panel.name = name
    table.insert(self.panels, panel)

    if not self.dropdown and #self.panels > 1 then
        self.dropdown = self:NewPanelSelector()
    end

    return panel
end

function Menu:AddLayoutPanel()
    local panel = self:NewPanel(L.Layout)

    panel.opacitySlider = panel:NewOpacitySlider()
    panel.fadeSlider = panel:NewFadeSlider()
    panel.scaleSlider = panel:NewScaleSlider()
    panel.paddingSlider = panel:NewPaddingSlider()
    panel.spacingSlider = panel:NewSpacingSlider()
    panel.colsSlider = panel:NewColumnsSlider()

    panel.width = 200
    return panel
end

function Menu:AddAdvancedPanel()
    local panel = self:NewPanel(L.Advanced)

    panel:NewLeftToRightCheckbox()
    panel:NewTopToBottomCheckbox()
    
    panel.width = 250
    return panel
end

do
    local info = {}
    local function AddItem(text, value, func, checked)
        info.text = text
        info.func = func
        info.value = value
        info.checked = checked
        info.arg1 = text
        UIDropDownMenu_AddButton(info)
    end

    local function Dropdown_OnShow(self)
        UIDropDownMenu_SetWidth(self, 120)
        UIDropDownMenu_Initialize(self, self.Initialize)
        UIDropDownMenu_SetSelectedValue(self, self:GetParent():GetSelectedPanel())
    end

    function Menu:NewPanelSelector()
        local f = CreateFrame('Frame', self:GetName() .. 'PanelSelector', self, 'UIDropDownMenuTemplate')
        _G[f:GetName() .. 'Text']:SetJustifyH('LEFT')

        f:SetScript('OnShow', Dropdown_OnShow)

        local function Item_OnClick(item, name)
            self:ShowPanel(name)
            UIDropDownMenu_SetSelectedValue(f, item.value)
        end

        function f:Initialize()
            local parent = self:GetParent()
            local selected = parent:GetSelectedPanel()
            for i, panel in ipairs(parent.panels) do
                AddItem(panel.name, i, Item_OnClick, i == selected)
            end
        end

        f:SetPoint('TOPLEFT', -4, -36)
        f:SetFrameLevel(self:GetFrameLevel() + 10)

        for _, panel in ipairs(self.panels) do
            panel:ClearAllPoints()
            panel:SetPoint('TOPLEFT', 12, -68)
            panel:SetPoint('BOTTOMRIGHT', -12, 12)
        end

        self.extraHeight = (self.extraHeight or 0) + 32

        return f
    end
end

local Panel = CleanBars:CreateClass('Frame')
Menu.Panel = Panel

Panel.width = 200
Panel.height = 0

function Panel:New(name, parent)
    local f = self:Bind(CreateFrame('Frame', parent:GetName() .. 'Panel' .. name, parent))
    f.controls = {}
    
    if parent.dropdown then
        f:SetPoint('TOPLEFT', 12, -68)
    else
        f:SetPoint('TOPLEFT', 12, -36)
    end
    f:SetPoint('BOTTOMRIGHT', -12, 12)
    f:Hide()

    return f
end

function Panel:Refresh()
    for _, control in ipairs(self.controls) do
        if control.showing and control.OnShow then
            control:OnShow()
        elseif control:IsVisible() and control.OnShow then
            control:OnShow()
        end
    end
end

function Panel:NewCheckButton(id, text)
    if not text then
        text = id
        id = tostring(text):gsub('[^%w]', '')
    end

    local button = CreateFrame('CheckButton', self:GetName() .. 'Check' .. id, self, 'InterfaceOptionsCheckButtonTemplate')
    _G[button:GetName() .. 'Text']:SetText(text)

    local prev = self.lastControl
    if prev then
        button:SetPoint('TOPLEFT', prev, 'BOTTOMLEFT', 0, -4)
    else
        button:SetPoint('TOPLEFT', 4, -4)
    end
    
    self.height = self.height + 26
    self.lastControl = button
    table.insert(self.controls, button)

    return button
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

    local function Slider_OnShow(self)
        self.showing = true
        if self.OnShow then
            self:OnShow()
        end
        self.showing = nil
    end

    local function Slider_OnValueChanged(self, value)
        if not self.showing then
            self:UpdateValue(value)
        end

        if self.UpdateText then
            self:UpdateText(value)
        else
            self.valText:SetText(value)
        end
    end

    function Panel:NewSlider(id, text, low, high, step, OnShow, UpdateValue, UpdateText)
        if type(text) == 'number' then
            UpdateText = UpdateValue
            UpdateValue = OnShow
            OnShow = step
            step = high
            high = low
            low = text
            text = id
            id = tostring(text):gsub('[^%w]', '')
        end

        local name = self:GetName() .. 'Slider' .. id

        local slider = CreateFrame('Slider', name, self, 'OptionsSliderTemplate')
        slider:SetMinMaxValues(low, high)
        slider:SetValueStep(step)
        slider:EnableMouseWheel(true)
        BlizzardOptionsPanel_Slider_Enable(slider) 

        _G[name .. 'Text']:SetText(text)
        _G[name .. 'Low']:SetText('')
        _G[name .. 'High']:SetText('')

        local valString = slider:CreateFontString(nil, 'BACKGROUND')
        valString:SetFontObject('GameFontHighlightSmall')
        valString:SetPoint('LEFT', slider, 'RIGHT', 12, 0)
        slider.valText = valString

        slider.OnShow = OnShow
        slider.UpdateValue = UpdateValue
        slider.UpdateText = UpdateText

        slider:SetScript('OnShow', Slider_OnShow)
        slider:SetScript('OnValueChanged', Slider_OnValueChanged)
        slider:SetScript('OnMouseWheel', Slider_OnMouseWheel)

        local prev = self.lastControl
        if prev then
            slider:SetPoint('TOPLEFT', prev, 'BOTTOMLEFT', 0, -22)
        else
            slider:SetPoint('TOPLEFT', 4, -14)
        end
        
        self.height = self.height + 38
        self.lastControl = slider
        table.insert(self.controls, slider)

        return slider
    end
end

do
    local function Slider_OnShow(self)
        self:SetValue(self:GetParent().owner:GetScale() * 100)
    end

    local function Slider_UpdateValue(self, value)
        self:GetParent().owner:SetFrameScale(value / 100)
    end

    function Panel:NewScaleSlider()
        return self:NewSlider('Scale', L.Scale, 50, 150, 1, Slider_OnShow, Slider_UpdateValue)
    end
end

do
    local function Slider_OnShow(self)
        self:SetValue(self:GetParent().owner:GetFrameAlpha() * 100)
    end

    local function Slider_UpdateValue(self, value)
        self:GetParent().owner:SetFrameAlpha(value / 100)
    end

    function Panel:NewOpacitySlider()
        return self:NewSlider('Opacity', L.Opacity, 0, 100, 1, Slider_OnShow, Slider_UpdateValue)
    end
end

do
    local function Slider_OnShow(self)
        self:SetValue(self:GetParent().owner:GetFadeMultiplier() * 100)
    end

    local function Slider_UpdateValue(self, value)
        self:GetParent().owner:SetFadeMultiplier(value / 100)
    end

    function Panel:NewFadeSlider()
        return self:NewSlider('Fade', L.FadedOpacity, 0, 100, 1, Slider_OnShow, Slider_UpdateValue)
    end
end

do
    local function Slider_OnShow(self)
        self:SetValue(self:GetParent().owner:GetPadding())
    end

    local function Slider_UpdateValue(self, value)
        self:GetParent().owner:SetPadding(value)
    end

    function Panel:NewPaddingSlider()
        return self:NewSlider('Padding', L.Padding, -16, 32, 1, Slider_OnShow, Slider_UpdateValue)
    end
end

do
    local function Slider_OnShow(self)
        self:SetValue(self:GetParent().owner:GetSpacing())
    end

    local function Slider_UpdateValue(self, value)
        self:GetParent().owner:SetSpacing(value)
    end

    function Panel:NewSpacingSlider()
        return self:NewSlider('Spacing', L.Spacing, -8, 32, 1, Slider_OnShow, Slider_UpdateValue)
    end
end

do
    local function Slider_OnShow(self)
        local minVal, maxVal = 1, self:GetParent().owner:NumButtons()
        if maxVal > minVal then
            BlizzardOptionsPanel_Slider_Enable(self)
            self:SetMinMaxValues(minVal, maxVal)
        else
            BlizzardOptionsPanel_Slider_Disable(self)
            self:SetMinMaxValues(1, 1)
        end
        self:SetValue(self:GetParent().owner:NumColumns())
    end

    local function Slider_UpdateValue(self, value)
        self:GetParent().owner:SetColumns(value)
    end

    function Panel:NewColumnsSlider()
        return self:NewSlider('Columns', L.Columns, 1, 1, 1, Slider_OnShow, Slider_UpdateValue)
    end
end

do
    function Panel:NewLeftToRightCheckbox()
        local b = self:NewCheckButton('LeftToRight', L.LeftToRight)
        
        b:SetScript('OnShow', function(self)
            self:SetChecked(self:GetParent().owner:GetLeftToRight())
        end)
        b:SetScript('OnClick', function(self)
            self:GetParent().owner:SetLeftToRight(self:GetChecked() and true or false)
        end)
    end
    
    function Panel:NewTopToBottomCheckbox()         
        local b = self:NewCheckButton('TopToBottom', L.TopToBottom)
        
        b:SetScript('OnShow', function(self)
            self:SetChecked(self:GetParent().owner:GetTopToBottom())
        end)
        
        b:SetScript('OnClick', function(self)
            self:GetParent().owner:SetTopToBottom(self:GetChecked() and true or false)
        end)
    end
end