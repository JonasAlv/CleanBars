local _G = getfenv(0)
local ceil = math.ceil
local min = math.min
local max = math.max
local floor = math.floor
local format = string.format
local pairs = pairs
local ipairs = ipairs
local tostring = tostring
local select = select
local unpack = unpack
local UnregisterStateDriver = UnregisterStateDriver
local RegisterStateDriver = RegisterStateDriver
local InCombatLockdown = InCombatLockdown
local CreateFrame = CreateFrame
local HasAction = HasAction
local ActionButton_Update = ActionButton_Update
local SetCVar = SetCVar

local MAX_BUTTONS = 120
local NUM_POSSESS_BAR_BUTTONS = 12
local KeyBound = LibStub('LibKeyBound-1.0')
local ButtonFacade = LibStub('LibButtonFacade', true)

local ActionButton = CleanBars:CreateClass('CheckButton', CleanBars.BindableButton)
CleanBars.ActionButton = ActionButton
ActionButton.unused = {}
ActionButton.active = {}

function ActionButton:New(id)
    local b = self:Restore(id) or self:Create(id)
    if b then
        if not InCombatLockdown() then
            b:SetAttribute('showgrid', 0)
            b:SetAttribute('action--base', id)
            b:SetAttribute('_childupdate-action', [[
                local id = message and self:GetAttribute('action--' .. message) or self:GetAttribute('action--base')
                self:SetAttribute('action', id)
            ]])
        end

        b:UpdateGrid()
        b:UpdateHotkey(b.buttonType)
        b:UpdateMacro()

        local hotkey = _G[b:GetName() .. 'HotKey']
        if hotkey and hotkey:GetText() == _G['RANGE_INDICATOR'] then
            hotkey:SetText('')
        end

        self.active[id] = b

        return b
    end
end

local function Create(id)
    if id <= 12 then
        local b = _G['ActionButton' .. id]
        b.buttonType = 'ACTIONBUTTON'
        return b
    elseif id <= 24 then
        local b = _G['BonusActionButton' .. (id - 12)]
        b:UnregisterEvent('UPDATE_BONUS_ACTIONBAR')
        b.isBonus = nil
        b.buttonType = nil 
        return b
    elseif id <= 36 then
        return _G['MultiBarRightButton' .. (id-24)]
    elseif id <= 48 then
        return _G['MultiBarLeftButton' .. (id-36)]
    elseif id <= 60 then
        return _G['MultiBarBottomRightButton' .. (id-48)]
    elseif id <= 72 then
        return _G['MultiBarBottomLeftButton' .. (id-60)]
    end
    return CreateFrame('CheckButton', 'CleanBarsActionButton' .. (id-72), nil, 'ActionBarButtonTemplate')
end

function ActionButton:Create(id)
    local b = Create(id)
    if b then
        self:Bind(b)

        if not InCombatLockdown() then
            b:SetAttribute('bindingid', b:GetID())
            b:SetID(0)
            b:SetAttribute('useparent-actionpage', nil)
            b:SetAttribute('useparent-unit', true)
            b:ClearAllPoints()
        end

        b:EnableMouseWheel(true)
        b:SetScript('OnEnter', self.OnEnter)
        b:Skin()
    end
    return b
end

function ActionButton:Restore(id)
    local b = self.unused[id]
    if b then
        self.unused[id] = nil
        if not InCombatLockdown() then
            b:Show()
        end
        self.active[id] = b
        return b
    end
end

function ActionButton:Free()
    local id = self:GetAttribute('action--base')
    if not id then return end

    self.active[id] = nil

    self:UnregisterAllEvents()
    if not InCombatLockdown() then
        self:SetParent(nil)
        self:Hide()
    end
    self.eventsRegistered = nil
    self.action = nil

    self.unused[id] = self
end

function ActionButton:OnEnter()
    if CleanBars:ShowTooltips() then
        ActionButton_SetTooltip(self)
    end
    KeyBound:Set(self)
end

hooksecurefunc('ActionButton_UpdateHotkeys', ActionButton.UpdateHotkey)

function ActionButton:UpdateGrid()
    local show = (self:GetAttribute('showgrid') or 0) > 0
    local name = self:GetName()
    
    if show then
        self.showgrid = 1
        local normalTexture = _G[name .. 'NormalTexture']
        if normalTexture then
            normalTexture:SetVertexColor(1, 1, 1, 0.5)
        end
        if not InCombatLockdown() then
            self:Show()
        end
    else
        self.showgrid = 0
        local action = self:GetAttribute('action') or self:GetAttribute('action--base')
        if action and not HasAction(action) then
            if not InCombatLockdown() then
                self:Hide()
            end
        end
    end
end

function ActionButton:UpdateMacro()
    local name = _G[self:GetName() .. 'Name']
    if not name then return end

    if CleanBars:ShowMacroText() then
        name:Show()
    else
        name:Hide()
    end
end

function ActionButton:LoadAction()
    local parent = self:GetParent()
    local state = parent and parent:GetAttribute('state-page')
    local id = state and self:GetAttribute('action--' .. state) or self:GetAttribute('action--base')
    if not InCombatLockdown() then
        self:SetAttribute('action', id)
    end
end

function ActionButton:Skin()
    if ButtonFacade then
        ButtonFacade:Group('CleanBars', 'Action Bar'):AddButton(self)
    else
        local icon = _G[self:GetName() .. 'Icon']
        if icon then icon:SetTexCoord(0.06, 0.94, 0.06, 0.94) end
        
        local normal = self:GetNormalTexture()
        if normal then normal:SetVertexColor(1, 1, 1, 0.5) end
    end
end

local ActionBar = CleanBars:CreateClass('Frame', CleanBars.Frame)
CleanBars.ActionBar = ActionBar

local POSSESSED_CONDITIONAL = '[bonusbar:5]'

ActionBar.defaultOffsets = {
    __index = function(t, i)
        t[i] = {}
        return t[i]
    end
}

ActionBar.mainbarOffsets = {
    __index = function(t, i)
        local pages = {
            ['[bar:2]'] = 1,
            ['[bar:3]'] = 2,
            ['[bar:4]'] = 3,
            ['[bar:5]'] = 4,
            ['[bar:6]'] = 5,
        }

        if i == 'DRUID' then
            pages['[bonusbar:1]'] = 6
            pages['[bonusbar:2]'] = 7
            pages['[bonusbar:3]'] = 8
            pages['[bonusbar:4]'] = 9
        elseif i == 'WARRIOR' then
            pages['[bonusbar:1]'] = 6
            pages['[bonusbar:2]'] = 7
            pages['[bonusbar:3]'] = 8
        elseif i == 'PRIEST' then
            pages['[bonusbar:1]'] = 6
        elseif i == 'ROGUE' then
            pages['[bonusbar:1]'] = 6
            pages['[form:3]'] = 6 
        end

        t[i] = pages
        return pages
    end
}

ActionBar.conditions = {
    '[mod:SELFCAST]',
    '[mod:alt,mod:ctrl,mod:shift]',
    '[mod:alt,mod:ctrl]',
    '[mod:alt,mod:shift]',
    '[mod:ctrl,mod:shift]',
    '[mod:alt]',
    '[mod:ctrl]',
    '[mod:shift]',
    POSSESSED_CONDITIONAL,
    '[bar:2]',
    '[bar:3]',
    '[bar:4]',
    '[bar:5]',
    '[bar:6]',
    '[bonusbar:1,stealth]', 
    '[form:2]',
    '[form:3]',
    '[bonusbar:1]',
    '[bonusbar:2]',
    '[bonusbar:3]',
    '[bonusbar:4]',
    '[help]',
    '[harm]',
    '[noexists]'
}

ActionBar.class = select(2, UnitClass('player'))
local active = {}

function ActionBar:New(id)
    local f = self.super.New(self, id)
    f.sets.pages = setmetatable(f.sets.pages, f.id == 1 and self.mainbarOffsets or self.defaultOffsets)

    f.pages = f.sets.pages[f.class]
    f.baseID = f:MaxLength() * (id-1)

    f:LoadStateController()
    f:LoadButtons()
    f:UpdateStateDriver()
    f:Layout()
    f:UpdateGrid()
    f:UpdateRightClickUnit()

    active[id] = f

    return f
end

function ActionBar:GetDefaults()
    local defaults = {}
    defaults.point = 'BOTTOM'
    defaults.x = 0
    defaults.y = 40*(self.id-1)
    defaults.pages = {}
    defaults.spacing = 4
    defaults.padW = 2
    defaults.padH = 2
    defaults.numButtons = self:MaxLength()

    return defaults
end

function ActionBar:Free()
    active[self.id] = nil
    self.super.Free(self)
end

function ActionBar:MaxLength()
    return floor(MAX_BUTTONS / CleanBars:NumBars())
end

function ActionBar:LoadButtons()
    for i = 1, self:NumButtons() do
        local b = ActionButton:New(self.baseID + i)
        if b then
            if not InCombatLockdown() then
                b:SetParent(self.header)
            end
            self.buttons[i] = b
        else
            break
        end
    end
    self:UpdateActions()
end

function ActionBar:AddButton(i)
    local b = ActionButton:New(self.baseID + i)
    if b then
        self.buttons[i] = b
        if not InCombatLockdown() then
            b:SetParent(self.header)
        end
        b:LoadAction()
        self:UpdateAction(i)
        self:UpdateGrid()
    end
end

function ActionBar:RemoveButton(i)
    local b = self.buttons[i]
    if b then
        self.buttons[i] = nil
        b:Free()
    end
end

function ActionBar:SetPage(condition, page)
    self.pages[condition] = page
    self:UpdateStateDriver()
end

function ActionBar:GetPage(condition)
    return self.pages[condition]
end

function ActionBar:UpdateStateDriver()
    if not InCombatLockdown() then
        UnregisterStateDriver(self.header, 'page', 0)
    end

    local header = ''
    for state,condition in ipairs(self.conditions) do
        if condition == POSSESSED_CONDITIONAL then
            if self:IsPossessBar() then
                header = header .. condition .. 'possess;'
            end 
        elseif self:GetPage(condition) then
            header = header .. condition .. 'S' .. state .. ';'
        end
    end

    if header ~= '' then
        if not InCombatLockdown() then
            RegisterStateDriver(self.header, 'page', header .. 0)
        end
    end

    self:UpdateActions()
    self:RefreshActions()
end

local function ToValidID(id)
    return (id - 1) % MAX_BUTTONS + 1
end

function ActionBar:UpdateAction(i)
    local b = self.buttons[i]
    if not b then return end
    local maxSize = self:MaxLength()

    for state,condition in ipairs(self.conditions) do
        local page = self:GetPage(condition)
        local id = page and ToValidID(b:GetAttribute('action--base') + (self.id + page - 1)*maxSize) or nil
        
        if not InCombatLockdown() then
            b:SetAttribute('action--S' .. state, id)
        end
    end

    if self:IsPossessBar() and i <= NUM_POSSESS_BAR_BUTTONS then
        if not InCombatLockdown() then
            b:SetAttribute('action--possess', MAX_BUTTONS + i)
        end
    else
        if not InCombatLockdown() then
            b:SetAttribute('action--possess', nil)
        end
    end
end

function ActionBar:UpdateActions()
    local maxSize = self:MaxLength()

    for state,condition in ipairs(self.conditions) do
        local page = self:GetPage(condition)
        for i,b in pairs(self.buttons) do
            local id = page and ToValidID(i + (self.id + page - 1)*maxSize) or nil
            if not InCombatLockdown() then
                b:SetAttribute('action--S' .. state, id)
            end
        end
    end

    if self:IsPossessBar() then
        for i = 1, min(#self.buttons, NUM_POSSESS_BAR_BUTTONS) do
            if not InCombatLockdown() then
                self.buttons[i]:SetAttribute('action--possess', MAX_BUTTONS + i)
            end
        end
        for i = NUM_POSSESS_BAR_BUTTONS + 1, #self.buttons do
            if not InCombatLockdown() then
                self.buttons[i]:SetAttribute('action--possess', nil)
            end
        end
    else
        for _,b in pairs(self.buttons) do
            if not InCombatLockdown() then
                b:SetAttribute('action--possess', nil)
            end
        end
    end
end

function ActionBar:LoadStateController()
    if not InCombatLockdown() then
        self.header:SetAttribute('_onstate-page', [[ control:ChildUpdate('action', newstate) ]])
    end
end

function ActionBar:RefreshActions()
    local state = self.header:GetAttribute('state-page')
    if state then
        self.header:Execute(format([[ control:ChildUpdate('action', '%s') ]], state))
    else
        self.header:Execute([[ control:ChildUpdate('action', nil) ]])
    end
end

function ActionBar:IsPossessBar()
    return self == CleanBars:GetPossessBar()
end

function ActionBar:ShowGrid()
    for _,b in pairs(self.buttons) do
        if not InCombatLockdown() then
            b:SetAttribute('showgrid', 1)
        end
        b:UpdateGrid()
    end
end

function ActionBar:HideGrid()
    for _,b in pairs(self.buttons) do
        if not InCombatLockdown() then
            b:SetAttribute('showgrid', 0)
        end
        b:UpdateGrid()
    end
end

function ActionBar:UpdateGrid()
    local show = CleanBars:ShowGrid() and 1 or 0
    if not InCombatLockdown() then
        SetCVar("alwaysShowActionBars", show)
    end
    for _,b in pairs(self.buttons) do
        if not InCombatLockdown() then
            b:SetAttribute('showgrid', show)
        end
        b:UpdateGrid()
    end
end

function ActionBar:KEYBOUND_ENABLED()
    self:ShowGrid()
end

function ActionBar:KEYBOUND_DISABLED()
    self:UpdateGrid()
end

function ActionBar:UpdateRightClickUnit()
    if not InCombatLockdown() then
        self.header:SetAttribute('*unit2', CleanBars:GetRightClickUnit())
    end
end

function ActionBar:ForAll(method, ...)
    for _,f in pairs(active) do
        if f[method] then f[method](f, ...) end
    end
end

do
    local L

    local function ConditionSlider_OnShow(self)
        self:SetMinMaxValues(-1, CleanBars:NumBars() - 1)
        self:SetValue(self:GetParent().owner:GetPage(self.condition) or -1)
    end

    local function ConditionSlider_UpdateValue(self, value)
        self:GetParent().owner:SetPage(self.condition, (value > -1 and value) or nil)
    end

    local function ConditionSlider_UpdateText(self, value)
        if value > -1 then
            local page = (self:GetParent().owner.id + value - 1) % CleanBars:NumBars() + 1
            self.valText:SetFormattedText(L.Bar, page)
        else
            self.valText:SetText(DISABLE)
        end
    end

    local function ConditionSlider_New(panel, condition, text)
        local id = tostring(condition):gsub('[^%w]', '')
        local s = panel:NewSlider(id, text or condition, -1, CleanBars:NumBars() - 1, 1, ConditionSlider_OnShow, ConditionSlider_UpdateValue, ConditionSlider_UpdateText)
        s.condition = condition
        s:SetWidth(s:GetWidth() + 28)

        local title = _G[s:GetName() .. 'Text']
        title:ClearAllPoints()
        title:SetPoint('BOTTOMLEFT', s, 'TOPLEFT')
        title:SetJustifyH('LEFT')

        local value = s.valText
        value:ClearAllPoints()
        value:SetPoint('BOTTOMRIGHT', s, 'TOPRIGHT')
        value:SetJustifyH('RIGHT')

        return s
    end

    local function AddLayout(self)
        local p = self:AddLayoutPanel()

        local size = p:NewSlider('Size', L.Size, 1, 1, 1, function(self)
            self:SetMinMaxValues(1, self:GetParent().owner:MaxLength())
            self:SetValue(self:GetParent().owner:NumButtons())
        end, function(self, value)
            local owner = self:GetParent().owner
            owner:SetNumButtons(value)
            if p.colsSlider and p.colsSlider.OnShow then
                p.colsSlider:OnShow()
            end
        end)
    end
    
    local function AddAdvancedLayout(self)
        self:AddAdvancedPanel()
    end
    
    local function AddClass(self)
        local lClass, class = UnitClass('player')
        if class == 'WARRIOR' or class == 'DRUID' or class == 'PRIEST' or class == 'ROGUE' or class == 'WARLOCK' then
            local p = self:NewPanel(lClass)
            if class == 'WARRIOR' then
                ConditionSlider_New(p, '[bonusbar:3]', GetSpellInfo(2458))
                ConditionSlider_New(p, '[bonusbar:2]', GetSpellInfo(71))
                ConditionSlider_New(p, '[bonusbar:1]', GetSpellInfo(2457))
            elseif class == 'DRUID' then
                ConditionSlider_New(p, '[bonusbar:4]', GetSpellInfo(24858))
                ConditionSlider_New(p, '[bonusbar:3]', GetSpellInfo(5487))
                ConditionSlider_New(p, '[bonusbar:2]', GetSpellInfo(33891))
                ConditionSlider_New(p, '[bonusbar:1,stealth]', GetSpellInfo(5215))
                ConditionSlider_New(p, '[bonusbar:1]', GetSpellInfo(768))
            elseif class == 'PRIEST' then
                ConditionSlider_New(p, '[bonusbar:1]', GetSpellInfo(15473))
            elseif class == 'ROGUE' then
                ConditionSlider_New(p, '[bonusbar:1]', GetSpellInfo(1784))
                ConditionSlider_New(p, '[form:3]', GetSpellInfo(51713))
            elseif class == 'WARLOCK' then
                ConditionSlider_New(p, '[form:2]', GetSpellInfo(47241))
            end
        end
    end

    local function AddPaging(self)
        local p = self:NewPanel(L.QuickPaging)
        for i = 6, 2, -1 do
            ConditionSlider_New(p, format('[bar:%d]', i), _G['BINDING_NAME_ACTIONPAGE' .. i])
        end
    end

    local function AddModifier(self)
        local p = self:NewPanel(L.Modifiers)
        ConditionSlider_New(p, '[mod:SELFCAST]', AUTO_SELF_CAST_KEY_TEXT)
        ConditionSlider_New(p, '[mod:alt,mod:ctrl,mod:shift]', L.CtrlAltShift)
        ConditionSlider_New(p, '[mod:alt,mod:shift]', L.AltShift)
        ConditionSlider_New(p, '[mod:ctrl,mod:shift]', L.CtrlShift)
        ConditionSlider_New(p, '[mod:alt,mod:ctrl]', L.CtrlAlt)
        ConditionSlider_New(p, '[mod:shift]', SHIFT_KEY)
        ConditionSlider_New(p, '[mod:alt]', ALT_KEY)
        ConditionSlider_New(p, '[mod:ctrl]', CTRL_KEY)
    end

    local function AddTargeting(self)
        local p = self:NewPanel(L.Targeting)
        ConditionSlider_New(p, '[noexists]', NONE)
        ConditionSlider_New(p, '[harm]', L.Harm)
        ConditionSlider_New(p, '[help]', L.Help)
    end

    local function AddShowState(self)
        local p = self:NewPanel(L.ShowStates)
        p.height = 56

        local editBox = CreateFrame('EditBox', p:GetName() .. 'StateText', p,  'InputBoxTemplate')
        editBox:SetWidth(148) editBox:SetHeight(20)
        editBox:SetPoint('TOPLEFT', 12, -10)
        editBox:SetAutoFocus(false)
        editBox:SetScript('OnShow', function(self)
            self:SetText(self:GetParent().owner:GetShowStates() or '')
        end)
        editBox:SetScript('OnEnterPressed', function(self)
            local text = self:GetText()
            self:GetParent().owner:SetShowStates(text ~= '' and text or nil)
        end)
        editBox:SetScript('OnEditFocusLost', function(self) self:HighlightText(0, 0) end)
        editBox:SetScript('OnEditFocusGained', function(self) self:HighlightText() end)

        local set = CreateFrame('Button', p:GetName() .. 'Set', p, 'UIPanelButtonTemplate')
        set:SetWidth(30) set:SetHeight(20)
        set:SetText(L.Set)
        set:SetScript('OnClick', function(self)
            local text = editBox:GetText()
            self:GetParent().owner:SetShowStates(text ~= '' and text or nil)
            editBox:SetText(self:GetParent().owner:GetShowStates() or '')
        end)
        set:SetPoint('BOTTOMRIGHT', -8, 2)

        return p
    end

    function ActionBar:CreateMenu()
        local menu = CleanBars:NewMenu(self.id)

        L = ConfigLocale
        AddLayout(menu)
        AddClass(menu)
        AddPaging(menu)
        AddModifier(menu)
        AddTargeting(menu)
        AddShowState(menu)
        AddAdvancedLayout(menu)

        ActionBar.menu = menu
    end
end