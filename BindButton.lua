local _G = getfenv(0)
local format = string.format
local select = select
local GetBindingKey = GetBindingKey
local GetBindingText = GetBindingText
local SetBinding = SetBinding
local SetBindingClick = SetBindingClick
local InCombatLockdown = InCombatLockdown

local BindableButton = CleanBars:CreateClass('CheckButton')
CleanBars.BindableButton = BindableButton

local KeyBound = LibStub('LibKeyBound-1.0')

function BindableButton:UpdateHotkey(buttonType)
    local key = BindableButton.GetHotkey(self, buttonType)
    local hotkeyText = _G[self:GetName() .. 'HotKey']
    
    if not hotkeyText then return end

    if key ~= '' and CleanBars:ShowBindingText() then
        hotkeyText:SetText(key)
        hotkeyText:Show()
    else
        hotkeyText:SetText('') 
        hotkeyText:Hide()
    end
end

function BindableButton:GetHotkey(buttonType)
    local key = BindableButton.GetBlizzBindings(self, buttonType) or BindableButton.GetClickBindings(self)
    return key and KeyBound:ToShortKey(key) or ''
end

function BindableButton:GetBlizzBindings(buttonType)
    local bType = buttonType or self.buttonType
    if bType then
        local id = self:GetAttribute('bindingid') or self:GetID()
        return GetBindingKey(bType .. id)
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
    local blizzKeys = getKeyStrings(BindableButton.GetBlizzBindings(self))
    local clickKeys = getKeyStrings(BindableButton.GetClickBindings(self))

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
    if InCombatLockdown() then return end
    
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
    if InCombatLockdown() then return end
    ClearBindings(BindableButton.GetBlizzBindings(self))
    ClearBindings(BindableButton.GetClickBindings(self))
end