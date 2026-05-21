local _G = getfenv(0)
local format = string.format

local KeyBound = LibStub('LibKeyBound-1.0')
local InCombatLockdown = InCombatLockdown
local unused

local PetButton = CleanBars:CreateClass('CheckButton', CleanBars.BindableButton)

function PetButton:New(id)
    local b = self:Restore(id) or self:Create(id)
    if b then
        b:UpdateHotkey()
    end
    return b
end

function PetButton:Create(id)
    local b = self:Bind(_G['PetActionButton' .. id])
    if b then
        b.buttonType = 'BONUSACTIONBUTTON'
        b:SetScript('OnEnter', self.OnEnter)
        b:Skin()
    end
    return b
end

function PetButton:Skin()
    local ButtonFacade = LibStub('LibButtonFacade', true)
    if ButtonFacade then
        ButtonFacade:Group('CleanBars', 'Pet Bar'):AddButton(self)
    else
        local icon = _G[self:GetName() .. 'Icon']
        if icon then icon:SetTexCoord(0.06, 0.94, 0.06, 0.94) end
        
        local normal = self:GetNormalTexture()
        if normal then normal:SetVertexColor(1, 1, 1, 0.5) end
    end
end

function PetButton:Restore(id)
    local b = unused and unused[id]
    if b then
        unused[id] = nil
        if not InCombatLockdown() then
            b:Show()
        end
        return b
    end
end

function PetButton:Free()
    if not unused then unused = {} end
    unused[self:GetID()] = self

    if not InCombatLockdown() then
        self:SetParent(nil)
        self:Hide()
    end
end

function PetButton:OnEnter()
    if CleanBars:ShowTooltips() then
        PetActionButton_OnEnter(self)
    end
    KeyBound:Set(self)
end

hooksecurefunc('PetActionButton_SetHotkeys', PetButton.UpdateHotkey)

local PetBar = CleanBars:CreateClass('Frame', CleanBars.Frame)
CleanBars.PetBar  = PetBar

function PetBar:New()
    local f = self.super.New(self, 'pet')
    f:LoadButtons()
    f:Layout()
    return f
end

function PetBar:GetShowStates()
    return '[target=pet,exists,nobonusbar:5]show;hide'
end

function PetBar:GetDefaults()
    return {
        point = 'CENTER',
        x = 0,
        y = -32,
        spacing = 6
    }
end

function PetBar:NumButtons()
    return NUM_PET_ACTION_SLOTS or 10
end

function PetBar:AddButton(i)
    local b = PetButton:New(i)
    if b then
        if not InCombatLockdown() then
            b:SetParent(self.header)
        end
        self.buttons[i] = b
    end
end

function PetBar:RemoveButton(i)
    local b = self.buttons[i]
    if b then
        self.buttons[i] = nil
        b:Free()
    end
end

function PetBar:KEYBOUND_ENABLED()
    if not InCombatLockdown() then
        self.header:SetAttribute('state-visibility', 'display')
    end

    for _,button in pairs(self.buttons) do
        if not InCombatLockdown() then
            button:Show()
        end
    end
end

function PetBar:KEYBOUND_DISABLED()
    self:UpdateShowStates()

    local petBarShown = PetHasActionBar()
    for _,button in pairs(self.buttons) do
        if petBarShown and GetPetActionInfo(button:GetID()) then
            if not InCombatLockdown() then
                button:Show()
            end
        else
            if not InCombatLockdown() then
                button:Hide()
            end
        end
    end
end