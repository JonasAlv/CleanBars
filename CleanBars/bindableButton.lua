local BindableButton = CleanBars:CreateClass('CheckButton')
CleanBars.BindableButton = BindableButton

local KeyBound = LibStub('LibKeyBound-1.0')
local _G = _G

function BindableButton:UpdateHotkey(buttonType)
	local key = BindableButton.GetHotkey(self, buttonType)
	if key ~= ''  and CleanBars:ShowBindingText() then
		_G[self:GetName()..'HotKey']:SetText(key)
		_G[self:GetName()..'HotKey']:Show()
	else
		_G[self:GetName()..'HotKey']:SetText('') 
		_G[self:GetName()..'HotKey']:Hide()
	end
end

function BindableButton:GetHotkey(buttonType)
	local key = BindableButton.GetBlizzBindings(self, buttonType) or BindableButton.GetClickBindings(self)
	return key and KeyBound:ToShortKey(key) or ''
end

function BindableButton:GetBlizzBindings(buttonType)
	local buttonType = buttonType or self.buttonType
	if buttonType then
		local id = self:GetAttribute('bindingid') or self:GetID()
		return GetBindingKey(buttonType .. id)
	end
end

function BindableButton:GetClickBindings()
	return GetBindingKey(format('CLICK %s:LeftButton', self:GetName()))
end

local function getKeyStrings(...)
	local keys
	for i = 1, select('#', ...) do
		local key = select(i, ...)
		if keys then
			keys = keys .. ", " .. GetBindingText(key, "KEY_")
		else
			keys = GetBindingText(key, "KEY_")
		end
	end
	return keys
end

function BindableButton:GetBindings()
	local blizzKeys = getKeyStrings(self:GetBlizzBindings())
	local clickKeys = getKeyStrings(self:GetClickBindings())

	if blizzKeys then
		if clickKeys then
			return blizzKeys .. ', ' .. clickKeys
		end
		return blizzKeys
	else
		return clickKeys
	end
end

function BindableButton:SetKey(key)
	if self.buttonType then
		local id = self:GetAttribute('bindingid') or self:GetID()
		SetBinding(key, self.buttonType .. id)
	else
		SetBindingClick(key, self:GetName(), 'LeftButton')
	end
end

local function ClearBindings(...)
	for i = 1, select('#', ...) do
		SetBinding(select(i, ...), nil)
	end
end

function BindableButton:ClearBindings()
	ClearBindings(self:GetBlizzBindings())
	ClearBindings(self:GetClickBindings())
end