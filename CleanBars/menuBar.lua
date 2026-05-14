local menuButtons
do
	local loadButtons = function(...)
		menuButtons = {}
		
		for i = 1, select('#', ...) do
			local b = select(i, ...)
			local name = b:GetName()
			if name and name:match('(%w+)MicroButton$') then
				table.insert(menuButtons, b)
			end
		end
	end
	loadButtons(_G['MainMenuBarArtFrame']:GetChildren())
end

do
	TalentMicroButton:SetScript('OnEvent', function(self, event)
		if (event == 'PLAYER_LEVEL_UP' or event == 'PLAYER_LOGIN') then
			if UnitCharacterPoints('player') > 0 and not CharacterFrame:IsShown() then
				SetButtonPulse(self, 60, 1)
			end
		elseif event == 'UPDATE_BINDINGS' then
			self.tooltipText =  MicroButtonTooltipText(TALENTS_BUTTON, 'TOGGLETALENTS')
		end
	end)
	TalentMicroButton:UnregisterAllEvents()
	TalentMicroButton:RegisterEvent('PLAYER_LEVEL_UP')
	TalentMicroButton:RegisterEvent('PLAYER_LOGIN')
	TalentMicroButton:RegisterEvent('UPDATE_BINDINGS')

	AchievementMicroButton:UnregisterAllEvents()

	local pvpbutton = _G["PVPMicroButtonTexture"]
	if pvpbutton then
		pvpbutton:ClearAllPoints()
		pvpbutton:SetPoint("CENTER", PVPMicroButton, "CENTER", 6, -6)
	end
	
	local resetTexture = function()
		local texture = _G["PVPMicroButtonTexture"]
		if texture then
			texture:ClearAllPoints()
			texture:SetPoint("CENTER", PVPMicroButton, "CENTER", 6, -6)
		end
	end
	
	PVPMicroButton:HookScript('OnMouseDown', resetTexture)
	PVPMicroButton:HookScript('OnMouseUp', resetTexture)
	PVPMicroButton:HookScript('OnEnter', resetTexture)
	PVPMicroButton:HookScript('OnLeave', resetTexture)
end

local MenuBar = CleanBars:CreateClass('Frame', CleanBars.Frame)
CleanBars.MenuBar  = MenuBar

function MenuBar:New()
	local f = self.super.New(self, 'menu')
	f:LoadButtons()
	f:Layout()

	return f
end

function MenuBar:GetDefaults()
	return {
		point = 'BOTTOMRIGHT',
		x = -244,
		y = 0,
	}
end

function MenuBar:NumButtons()
	return #menuButtons
end

function MenuBar:AddButton(i)
	local b = menuButtons[i]
	if b then
		b:SetParent(self.header)
		b:Show()

		self.buttons[i] = b
	end
end

function MenuBar:RemoveButton(i)
	local b = self.buttons[i]
	if b then
		b:SetParent(nil)
		b:Hide()

		self.buttons[i] = nil
	end
end

local WIDTH_OFFSET = 2
local HEIGHT_OFFSET = 20

function MenuBar:Layout()
	if #self.buttons > 0 then
		local cols = min(self:NumColumns(), #self.buttons)
		local rows = ceil(#self.buttons / cols)
		local pW, pH = self:GetPadding()
		local spacing = self:GetSpacing()

		local b = self.buttons[1]
		local w = b:GetWidth() + spacing - WIDTH_OFFSET
		local h = b:GetHeight() + spacing - HEIGHT_OFFSET

		for i,b in pairs(self.buttons) do
			local col = (i-1) % cols
			local row = ceil(i / cols) - 1
			b:ClearAllPoints()
			b:SetPoint('TOPLEFT', w*col + pW, -(h*row + pH) + HEIGHT_OFFSET)
		end

		self:SetWidth(max(w*cols - spacing + pW*2 + WIDTH_OFFSET, 8))
		self:SetHeight(max(h*ceil(#self.buttons/cols) - spacing + pH*2, 8))
	else
		self:SetWidth(30); self:SetHeight(30)
	end
end