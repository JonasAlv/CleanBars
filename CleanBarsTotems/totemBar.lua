local class, enClass = UnitClass('player')
if enClass ~= 'SHAMAN' then
	return
end

local DTB = CleanBars:NewModule('totems', 'AceEvent-3.0')
local totemBarClass


local MAX_TOTEMS = MAX_TOTEMS 
local RECALL_SPELL = TOTEM_MULTI_CAST_RECALL_SPELLS[1]
local START_ACTION_ID = 132 
local SUMMON_SPELLS = TOTEM_MULTI_CAST_SUMMON_SPELLS

function DTB:Load()
	self:LoadTotemBars()

	self:RegisterEvent('UPDATE_MULTI_CAST_ACTIONBAR')
end

function DTB:Unload()
	self:FreeTotemBars()

	self:UnregisterEvent('PLAYER_REGEN_ENABLED')
	self:UnregisterEvent('UPDATE_MULTI_CAST_ACTIONBAR')
end

function DTB:UPDATE_MULTI_CAST_ACTIONBAR()
	if not InCombatLockdown() then
		self:LoadTotemBars()
	else
		self:RegisterEvent('PLAYER_REGEN_ENABLED')
	end
end

function DTB:PLAYER_REGEN_ENABLED()
	self:LoadTotemBars()
	self:UnregisterEvent('PLAYER_REGEN_ENABLED')
end

function DTB:LoadTotemBars()
	for i, spell in pairs(SUMMON_SPELLS) do
		local f = CleanBars.Frame:Get('totem' .. i)
		if f then
			f:LoadButtons()
		else
			totemBarClass:New(i, spell)
		end
	end
end

function DTB:FreeTotemBars()
	for i, _ in pairs(SUMMON_SPELLS) do
		local f = CleanBars.Frame:Get('totem' .. i)
		if f then
			f:Free()
		end
	end
end

TotemBar = CleanBars:CreateClass('Frame', CleanBars.Frame)

function totemBarClass:New(id, spell)
	local f = self.super.New(self, 'totem' .. id)
	f.totemBarID = id
	f.callSpell = spell
	f:LoadButtons()
	f:Layout()

	return f
end

function totemBarClass:GetDefaults()
	return {
		point = 'CENTER',
		spacing = 2,
		showRecall = true,
		showTotems = true
	}
end

function totemBarClass:NumButtons()
	local numButtons = 0

	if self:IsCallKnown() then
		numButtons = numButtons + 1
	end

	if self:ShowingTotems() then
		numButtons = numButtons + MAX_TOTEMS
	end

	if self:ShowingRecall() and self:IsRecallKnown() then
		numButtons = numButtons + 1
	end

	return numButtons
end

function totemBarClass:GetBaseID()
	return START_ACTION_ID + (MAX_TOTEMS * (self.totemBarID - 1))
end

function totemBarClass:SetShowRecall(show)
	self.sets.showRecall = show and true or false
	self:LoadButtons()
	self:Layout()
end

function totemBarClass:ShowingRecall()
	return self.sets.showRecall
end

function totemBarClass:SetShowTotems(show)
	self.sets.showTotems = show and true or false
	self:LoadButtons()
	self:Layout()
end

function totemBarClass:ShowingTotems()
	return self.sets.showTotems
end

local tinsert = table.insert

function totemBarClass:LoadButtons()
	local buttons = self.buttons

	for i, b in pairs(buttons) do
		b:Free()
		buttons[i] = nil
	end

	if self:IsCallKnown() then
		tinsert(buttons, self:GetCallButton())
	end

	if self:ShowingTotems() then
		for _, totemID in ipairs(TOTEM_PRIORITIES) do
			tinsert(buttons, self:GetTotemButton(totemID))
		end
	end

	if self:ShowingRecall() and self:IsRecallKnown() then
		tinsert(buttons, self:GetRecallButton())
	end

	self.header:Execute([[ control:ChildUpdate('action', nil) ]])
end

function totemBarClass:IsCallKnown()
	return IsSpellKnown(self.callSpell, false)
end

function totemBarClass:GetCallButton()
	return self:CreateSpellButton(self.callSpell)
end

function totemBarClass:IsRecallKnown()
	return IsSpellKnown(RECALL_SPELL, false)
end

function totemBarClass:GetRecallButton()
	return self:CreateSpellButton(RECALL_SPELL)
end

function totemBarClass:GetTotemButton(id)
	return self:CreateActionButton(self:GetBaseID() + id)
end

function totemBarClass:CreateSpellButton(spellID)
	local b = CleanBars.SpellButton:New(spellID)
	b:SetParent(self.header)
	return b
end

function totemBarClass:CreateActionButton(actionID)
	local b = CleanBars.ActionButton:New(actionID)
	b:SetParent(self.header)
	b:LoadAction()
	return b
end

function totemBarClass:AddLayoutPanel(menu)
	local L = CleanBarsConfigLocale
	local panel = menu:AddLayoutPanel()

	local showRecall = panel:NewCheckButton(L.ShowTotemRecall)

	showRecall:SetScript('OnClick', function(b)
		self:SetShowRecall(b:GetChecked());
		panel.colsSlider:OnShow() 
	end)

	showRecall:SetScript('OnShow', function(b)
		b:SetChecked(self:ShowingRecall())
	end)

	local showTotems = panel:NewCheckButton(L.ShowTotems)

	showTotems:SetScript('OnClick', function(b)
		self:SetShowTotems(b:GetChecked());
		panel.colsSlider:OnShow()
	end)

	showTotems:SetScript('OnShow', function(b)
		b:SetChecked(self:ShowingTotems())
	end)
end

function totemBarClass:CreateMenu()
	self.menu = CleanBars:NewMenu(self.id)
	self:AddLayoutPanel(self.menu)
	self.menu:AddAdvancedPanel()
end