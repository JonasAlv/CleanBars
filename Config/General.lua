local L = ConfigLocale
local CleanBars = CleanBars
local Options = CleanBars.Options

local lock = Options:NewButton(L.EnterConfigMode, 136, 22)
lock:SetScript('OnClick', function(self)
	CleanBars:ToggleLockedFrames()
	HideUIPanel(InterfaceOptionsFrame)
end)
lock:SetPoint('TOPLEFT', 12, -72)

local bind = Options:NewButton(L.EnterBindingMode, 136, 22)
bind:SetScript('OnClick', function(self)
	CleanBars:ToggleBindingMode()
	HideUIPanel(InterfaceOptionsFrame)
end)
bind:SetPoint('LEFT', lock, 'RIGHT', 4, 0)

local stickyBars = Options:NewCheckButton(L.StickyBars)
stickyBars:SetScript('OnShow', function(self)
	self:SetChecked(CleanBars:Sticky())
end)
stickyBars:SetScript('OnClick', function(self)
	CleanBars:SetSticky(self:GetChecked())
end)
stickyBars:SetPoint('TOPLEFT', lock, 'BOTTOMLEFT', 0, -24)

local linkedOpacity = Options:NewSmallCheckButton(L.LinkedOpacity)
linkedOpacity:SetScript('OnShow', function(self)
	self:SetChecked(CleanBars:IsLinkedOpacityEnabled())
end)
linkedOpacity:SetScript('OnClick', function(self)
	CleanBars:SetLinkedOpacity(self:GetChecked())
end)
linkedOpacity:SetPoint('TOP', stickyBars, 'BOTTOM', 8, -2)

local showMinimapButton = Options:NewCheckButton(L.ShowMinimapButton)
showMinimapButton:SetScript('OnShow', function(self)
	self:SetChecked(CleanBars:ShowingMinimap())
end)
showMinimapButton:SetScript('OnClick', function(self)
	CleanBars:SetShowMinimap(self:GetChecked())
end)
showMinimapButton:SetPoint('TOP', linkedOpacity, 'BOTTOM', -8, -10)


local lockButtons = Options:NewCheckButton(L.LockActionButtons)
lockButtons:SetScript('OnShow', function(self)
	self:SetChecked(LOCK_ACTIONBAR == '1')
end)
lockButtons:SetScript('OnClick', function(self, ...)
	_G['InterfaceOptionsActionBarsPanelLockActionBars']:Click(...)
end)
lockButtons:SetPoint('TOP', showMinimapButton, 'BOTTOM', 0, -10)

local showEmpty = Options:NewCheckButton(L.ShowEmptyButtons)
showEmpty:SetScript('OnShow', function(self)
	self:SetChecked(CleanBars:ShowGrid())
end)
showEmpty:SetScript('OnClick', function(self)
	CleanBars:SetShowGrid(self:GetChecked())
end)

showEmpty:SetPoint('TOP', lockButtons, 'BOTTOM', 0, -10)

local showBindings = Options:NewCheckButton(L.ShowBindingText)
showBindings:SetScript('OnShow', function(self)
	self:SetChecked(CleanBars:ShowBindingText())
end)
showBindings:SetScript('OnClick', function(self)
	CleanBars:SetShowBindingText(self:GetChecked())
end)
showBindings:SetPoint('TOP', showEmpty, 'BOTTOM', 0, -10)

local showMacros = Options:NewCheckButton(L.ShowMacroText)
showMacros:SetScript('OnShow', function(self)
	self:SetChecked(CleanBars:ShowMacroText())
end)
showMacros:SetScript('OnClick', function(self)
	CleanBars:SetShowMacroText(self:GetChecked())
end)
showMacros:SetPoint('TOP', showBindings, 'BOTTOM', 0, -10)

local showTooltips = Options:NewCheckButton(L.ShowTooltips)
showTooltips:SetScript('OnShow', function(self)
	self:SetChecked(CleanBars:ShowTooltips())
end)
showTooltips:SetScript('OnClick', function(self)
	CleanBars:SetShowTooltips(self:GetChecked())
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

	local function AddClickActionSelector(self, name, action)
		local dd = self:NewDropdown(name)

		dd:SetScript('OnShow', function(self)
			UIDropDownMenu_SetWidth(self, 110)
			UIDropDownMenu_Initialize(self, self.Initialize)
			UIDropDownMenu_SetSelectedValue(self, GetModifiedClick(action) or 'NONE')
		end)

		local function Item_OnClick(self)
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
		local dd = self:NewDropdown(L.RightClickUnit)

		dd:SetScript('OnShow', function(self)
			UIDropDownMenu_SetWidth(self, 110)
			UIDropDownMenu_Initialize(self, self.Initialize)
			UIDropDownMenu_SetSelectedValue(self, CleanBars:GetRightClickUnit() or 'NONE')
		end)

		local function Item_OnClick(self)
			CleanBars:SetRightClickUnit(self.value ~= 'NONE' and self.value or nil)
			UIDropDownMenu_SetSelectedValue(dd, self.value)
		end

		function dd:Initialize()
			local selected = CleanBars:GetRightClickUnit()  or 'NONE'

			AddItem(L.RCUPlayer, 'player', Item_OnClick, 'player' == selected)
			AddItem(L.RCUFocus, 'focus', Item_OnClick, 'focus' == selected)
			AddItem(L.RCUToT, 'targettarget', Item_OnClick, 'targettarget' == selected)
			AddItem(NONE_KEY, 'NONE', Item_OnClick, 'NONE' == selected)
		end
		return dd
	end

	local function AddPossessBarSelector(self)
		local dd = self:NewDropdown(L.PossessBar)

		dd:SetScript('OnShow', function(self)
			UIDropDownMenu_SetWidth(self, 110)
			UIDropDownMenu_Initialize(self, self.Initialize)
			UIDropDownMenu_SetSelectedValue(self, CleanBars:GetPossessBar().id)
		end)

		local function Item_OnClick(self)
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

	local quickMove = AddClickActionSelector(Options, L.QuickMoveKey, 'PICKUPACTION')
	quickMove:SetPoint('TOPRIGHT', -10, -120)

	local rightClickUnit = AddRightClickTargetSelector(Options)
	rightClickUnit:SetPoint('TOP', quickMove, 'BOTTOM', 0, -16)

	local possess = AddPossessBarSelector(Options)
	possess:SetPoint('TOP', rightClickUnit, 'BOTTOM', 0, -16)
end
