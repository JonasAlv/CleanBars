local L = ConfigLocale
local _G = getfenv(0)

local CleanBars = LibStub("AceAddon-3.0"):GetAddon("CleanBars")
local Options = CleanBars.Options

local function CombatBlock(self, revertFunc)
    if InCombatLockdown() then
        if revertFunc then 
            self:SetChecked(revertFunc()) 
        end
        CleanBars:Print("Can't change settings in combat.")
        return true
    end
    return false
end

local lock = Options:NewButton(L.EnterConfigMode, 136, 22)
lock:SetScript('OnClick', function(self)
    if CombatBlock(self) then return end
    CleanBars:ToggleLockedFrames()
    HideUIPanel(InterfaceOptionsFrame)
end)
lock:SetPoint('TOPLEFT', 12, -72)

local bind = Options:NewButton(L.EnterBindingMode, 136, 22)
bind:SetScript('OnClick', function(self)
    if CombatBlock(self) then return end
    CleanBars:ToggleBindingMode()
    HideUIPanel(InterfaceOptionsFrame)
end)
bind:SetPoint('LEFT', lock, 'RIGHT', 4, 0)

local stickyBars = Options:NewCheckButton('StickyBars', L.StickyBars)
stickyBars:SetScript('OnShow', function(self)
    self:SetChecked(CleanBars:Sticky())
end)
stickyBars:SetScript('OnClick', function(self)
    if CombatBlock(self, function() return CleanBars:Sticky() end) then return end
    CleanBars:SetSticky(self:GetChecked() and true or false)
end)
stickyBars:SetPoint('TOPLEFT', lock, 'BOTTOMLEFT', 0, -24)

local linkedOpacity = Options:NewSmallCheckButton('LinkedOpacity', L.LinkedOpacity)
linkedOpacity:SetScript('OnShow', function(self)
    self:SetChecked(CleanBars:IsLinkedOpacityEnabled())
end)
linkedOpacity:SetScript('OnClick', function(self)
    if CombatBlock(self, function() return CleanBars:IsLinkedOpacityEnabled() end) then return end
    CleanBars:SetLinkedOpacity(self:GetChecked() and true or false)
end)
linkedOpacity:SetPoint('TOP', stickyBars, 'BOTTOM', 8, -2)

local showMinimapButton = Options:NewCheckButton('ShowMinimapButton', L.ShowMinimapButton)
showMinimapButton:SetScript('OnShow', function(self)
    self:SetChecked(CleanBars:ShowingMinimap())
end)
showMinimapButton:SetScript('OnClick', function(self)
    if CombatBlock(self, function() return CleanBars:ShowingMinimap() end) then return end
    CleanBars:SetShowMinimap(self:GetChecked() and true or false)
end)
showMinimapButton:SetPoint('TOP', linkedOpacity, 'BOTTOM', -8, -10)

local lockButtons = Options:NewCheckButton('LockActionButtons', L.LockActionButtons)
lockButtons:SetScript('OnShow', function(self)
    self:SetChecked(LOCK_ACTIONBAR == '1')
end)
lockButtons:SetScript('OnClick', function(self, ...)
    if CombatBlock(self, function() return LOCK_ACTIONBAR == '1' end) then return end
    _G['InterfaceOptionsActionBarsPanelLockActionBars']:Click(...)
end)
lockButtons:SetPoint('TOP', showMinimapButton, 'BOTTOM', 0, -10)

local showEmpty = Options:NewCheckButton('ShowEmptyButtons', L.ShowEmptyButtons)
showEmpty:SetScript('OnShow', function(self)
    self:SetChecked(CleanBars:ShowGrid())
end)
showEmpty:SetScript('OnClick', function(self)
    if CombatBlock(self, function() return CleanBars:ShowGrid() end) then return end
    CleanBars:SetShowGrid(self:GetChecked() and true or false)
end)
showEmpty:SetPoint('TOP', lockButtons, 'BOTTOM', 0, -10)

local showBindings = Options:NewCheckButton('ShowBindingText', L.ShowBindingText)
showBindings:SetScript('OnShow', function(self)
    self:SetChecked(CleanBars:ShowBindingText())
end)
showBindings:SetScript('OnClick', function(self)
    if CombatBlock(self, function() return CleanBars:ShowBindingText() end) then return end
    CleanBars:SetShowBindingText(self:GetChecked() and true or false)
end)
showBindings:SetPoint('TOP', showEmpty, 'BOTTOM', 0, -10)

local showMacros = Options:NewCheckButton('ShowMacroText', L.ShowMacroText)
showMacros:SetScript('OnShow', function(self)
    self:SetChecked(CleanBars:ShowMacroText())
end)
showMacros:SetScript('OnClick', function(self)
    if CombatBlock(self, function() return CleanBars:ShowMacroText() end) then return end
    CleanBars:SetShowMacroText(self:GetChecked() and true or false)
end)
showMacros:SetPoint('TOP', showBindings, 'BOTTOM', 0, -10)

local showTooltips = Options:NewCheckButton('ShowTooltips', L.ShowTooltips)
showTooltips:SetScript('OnShow', function(self)
    self:SetChecked(CleanBars:ShowTooltips())
end)
showTooltips:SetScript('OnClick', function(self)
    if CombatBlock(self, function() return CleanBars:ShowTooltips() end) then return end
    CleanBars:SetShowTooltips(self:GetChecked() and true or false)
end)
showTooltips:SetPoint('TOP', showMacros, 'BOTTOM', 0, -10)

do
    local info = {}
    local function AddItem(text, value, func, checked, arg1)
        info.text = text
        info.func = func
        info.value = value
        info.checked = checked
        info.arg1 = arg1
        UIDropDownMenu_AddButton(info)
    end

    local function AddClickActionSelector(self, id, name, action)
        local dd = self:NewDropdown(id, name)

        dd:SetScript('OnShow', function(self)
            UIDropDownMenu_SetWidth(self, 110)
            UIDropDownMenu_Initialize(self, self.Initialize)
            UIDropDownMenu_SetSelectedValue(self, GetModifiedClick(action) or 'NONE')
        end)

        local function Item_OnClick(self)
            if InCombatLockdown() then
                CleanBars:Print("Can't change settings in combat.")
                return
            end
            SetModifiedClick(action, self.value)
            UIDropDownMenu_SetSelectedValue(dd, self.value)
            SaveBindings(GetCurrentBindingSet())
        end

        function dd:Initialize()
            local selected = GetModifiedClick(action) or 'NONE'
            AddItem(ALT_KEY, 'ALT', Item_OnClick, 'ALT' == selected)
            AddItem(CTRL_KEY, 'CTRL', Item_OnClick, 'CTRL' == selected)
            AddItem(SHIFT_KEY, 'SHIFT', Item_OnClick, 'SHIFT' == selected)
            AddItem(NONE_KEY, 'NONE', Item_OnClick, 'NONE' == selected)
        end
        return dd
    end

    local function AddRightClickTargetSelector(self)
        local dd = self:NewDropdown('RightClickUnit', L.RightClickUnit)

        dd:SetScript('OnShow', function(self)
            UIDropDownMenu_SetWidth(self, 110)
            UIDropDownMenu_Initialize(self, self.Initialize)
            UIDropDownMenu_SetSelectedValue(self, CleanBars:GetRightClickUnit() or 'NONE')
        end)

        local function Item_OnClick(self)
            if InCombatLockdown() then
                CleanBars:Print("Can't change settings in combat.")
                return
            end
            CleanBars:SetRightClickUnit(self.value ~= 'NONE' and self.value or nil)
            UIDropDownMenu_SetSelectedValue(dd, self.value)
        end

        function dd:Initialize()
            local selected = CleanBars:GetRightClickUnit() or 'NONE'
            AddItem(L.RCUPlayer, 'player', Item_OnClick, 'player' == selected)
            AddItem(L.RCUFocus, 'focus', Item_OnClick, 'focus' == selected)
            AddItem(L.RCUToT, 'targettarget', Item_OnClick, 'targettarget' == selected)
            AddItem(NONE_KEY, 'NONE', Item_OnClick, 'NONE' == selected)
        end
        return dd
    end

    local function AddPossessBarSelector(self)
        local dd = self:NewDropdown('PossessBar', L.PossessBar)

        dd:SetScript('OnShow', function(self)
            UIDropDownMenu_SetWidth(self, 110)
            UIDropDownMenu_Initialize(self, self.Initialize)
            UIDropDownMenu_SetSelectedValue(self, CleanBars:GetPossessBar().id)
        end)

        local function Item_OnClick(self)
            if InCombatLockdown() then
                CleanBars:Print("Can't change settings in combat.")
                return
            end
            CleanBars:SetPossessBar(self.value)
            UIDropDownMenu_SetSelectedValue(dd, self.value)
        end

        function dd:Initialize()
            local selected = CleanBars:GetPossessBar().id
            for i = 1, CleanBars:NumBars() do
                AddItem('Action Bar ' .. i, i, Item_OnClick, i == selected)
            end
        end
        return dd
    end

    local quickMove = AddClickActionSelector(Options, 'QuickMoveKey', L.QuickMoveKey, 'PICKUPACTION')
    quickMove:ClearAllPoints()
    quickMove:SetPoint('TOPLEFT', stickyBars, 'TOPRIGHT', 250, 0)

    local rightClickUnit = AddRightClickTargetSelector(Options)
    rightClickUnit:ClearAllPoints()
    rightClickUnit:SetPoint('TOPLEFT', quickMove, 'BOTTOMLEFT', 0, -24)

    local possess = AddPossessBarSelector(Options)
    possess:ClearAllPoints()
    possess:SetPoint('TOPLEFT', rightClickUnit, 'BOTTOMLEFT', 0, -24)
end

do
    local grid = CreateFrame('Frame', 'CleanBarsAlignmentGrid', UIParent)
    grid:SetAllPoints(UIParent)
    grid:SetFrameStrata('BACKGROUND')
    grid:Hide()
    
    grid.lines = {}
    
    grid.Build = function(self)
        for _, line in ipairs(self.lines) do line:Hide() end
        
        local w, h = UIParent:GetRight(), UIParent:GetTop()
        local size = 36
        local lineIndex = 1
        
        local function GetLine()
            local line = self.lines[lineIndex]
            if not line then
                line = self:CreateTexture(nil, 'BACKGROUND')
                self.lines[lineIndex] = line
            end
            lineIndex = lineIndex + 1
            line:Show()
            return line
        end

        local cx = GetLine()
        cx:SetTexture(0, 1, 1, 0.6)
        cx:SetPoint('TOP', UIParent, 'TOP', 0, 0)
        cx:SetPoint('BOTTOM', UIParent, 'BOTTOM', 0, 0)
        cx:SetWidth(1)

        local cy = GetLine()
        cy:SetTexture(0, 1, 1, 0.6)
        cy:SetPoint('LEFT', UIParent, 'LEFT', 0, 0)
        cy:SetPoint('RIGHT', UIParent, 'RIGHT', 0, 0)
        cy:SetHeight(1)

        local cols = math.floor(w / size / 2)
        local rows = math.floor(h / size / 2)

        for i = 1, cols do
            local right = GetLine()
            right:SetTexture(1, 1, 1, 0.15)
            right:SetPoint('TOP', UIParent, 'TOP', i * size, 0)
            right:SetPoint('BOTTOM', UIParent, 'BOTTOM', i * size, 0)
            right:SetWidth(1)

            local left = GetLine()
            left:SetTexture(1, 1, 1, 0.15)
            left:SetPoint('TOP', UIParent, 'TOP', -i * size, 0)
            left:SetPoint('BOTTOM', UIParent, 'BOTTOM', -i * size, 0)
            left:SetWidth(1)
        end

        for i = 1, rows do
            local up = GetLine()
            up:SetTexture(1, 1, 1, 0.15)
            up:SetPoint('LEFT', UIParent, 'LEFT', 0, i * size)
            up:SetPoint('RIGHT', UIParent, 'RIGHT', 0, i * size)
            up:SetHeight(1)

            local down = GetLine()
            down:SetTexture(1, 1, 1, 0.15)
            down:SetPoint('LEFT', UIParent, 'LEFT', 0, -i * size)
            down:SetPoint('RIGHT', UIParent, 'RIGHT', 0, -i * size)
            down:SetHeight(1)
        end
    end
    
    grid:RegisterEvent("DISPLAY_SIZE_CHANGED")
    grid:SetScript("OnEvent", grid.Build)
    grid:Build()
    
    hooksecurefunc(CleanBars, "SetLock", function(self, enable)
        if enable then
            grid:Hide()
        else
            grid:Show()
        end
    end)
end
