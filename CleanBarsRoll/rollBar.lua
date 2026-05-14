local DRB = CleanBars:NewModule('roll')
local L = CleanBarsLocale
local rollBarClass

function DRB:Load()
	self.frame = rollBarClass:New()
end

function DRB:Unload()
	self.frame:Free()
end

rollBarClass = CleanBars:CreateClass('Frame', CleanBars.Frame)

function rollBarClass:New()
	local f = self.super.New(self, 'roll', L.TipRollBar)
	f:LoadButtons()
	f:Layout()

	return f
end

function rollBarClass:GetDefaults()
	return {
		point = 'LEFT',
		numButtons = NUM_GROUP_LOOT_FRAMES,
		columns = 1,
		spacing = 2
	}
end

function rollBarClass:AddButton(i)
	local b =  _G['GroupLootFrame' .. (5 - i)]
	b:SetParent(self.header)
	self.buttons[i] = b
end

function rollBarClass:RemoveButton(i)
	local b = self.buttons[i]
	b:SetParent(nil)
	self.buttons[i] = nil
end

UIPARENT_MANAGED_FRAME_POSITIONS['GroupLootFrame1'] = nil