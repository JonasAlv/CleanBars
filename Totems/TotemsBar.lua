local TotemBar = CleanBars:CreateClass('Frame', CleanBars.Frame)
CleanBars.TotemBar = TotemBar

local MAX_TOTEMS = MAX_TOTEMS or 4 
local RECALL_SPELL = (TOTEM_MULTI_CAST_RECALL_SPELLS and TOTEM_MULTI_CAST_RECALL_SPELLS[1]) or 66842
local START_ACTION_ID = 132 
local SUMMON_SPELLS = TOTEM_MULTI_CAST_SUMMON_SPELLS or {66843, 66844, 16588}
local InCombatLockdown = InCombatLockdown

function TotemBar:Initialize()
    if not self.eventFrame then
        self.eventFrame = CreateFrame('Frame')
        self.eventFrame:RegisterEvent('UPDATE_MULTI_CAST_ACTIONBAR')
        self.eventFrame:SetScript('OnEvent', function(frame, event)
            if event == 'UPDATE_MULTI_CAST_ACTIONBAR' then
                if not InCombatLockdown() then
                    self:LoadBars()
                else
                    frame:RegisterEvent('PLAYER_REGEN_ENABLED')
                end
            elseif event == 'PLAYER_REGEN_ENABLED' then
                if not InCombatLockdown() then
                    self:LoadBars()
                    frame:UnregisterEvent('PLAYER_REGEN_ENABLED')
                end
            end
        end)
    end
    if not InCombatLockdown() then
        self:LoadBars()
    end
end

function TotemBar:LoadBars()
    if InCombatLockdown() then return end
    for i, spell in pairs(SUMMON_SPELLS) do
        local f = CleanBars.Frame:Get('totem' .. i)
        if f then
            f:LoadButtons()
        else
            self:New(i, spell)
        end
    end
end

function TotemBar:UnloadBars()
    if InCombatLockdown() then return end
    for i, _ in pairs(SUMMON_SPELLS) do
        local f = CleanBars.Frame:Get('totem' .. i)
        if f then
            f:Free()
        end
    end
end

function TotemBar:New(id, spell)
    local f = self.super.New(self, 'totem' .. id)
    f.totemBarID = id
    f.callSpell = spell
    if not InCombatLockdown() then
        f:LoadButtons()
        f:Layout()
    end

    return f
end

function TotemBar:GetDefaults()
    return {
        point = 'CENTER',
        spacing = 2,
        showRecall = true,
        showTotems = true
    }
end

function TotemBar:NumButtons()
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

function TotemBar:GetBaseID()
    return START_ACTION_ID + (MAX_TOTEMS * (self.totemBarID - 1))
end

function TotemBar:SetShowRecall(show)
    self.sets.showRecall = show and true or false
    if not InCombatLockdown() then
        self:LoadButtons()
        self:Layout()
    end
end

function TotemBar:ShowingRecall()
    return self.sets.showRecall
end

function TotemBar:SetShowTotems(show)
    self.sets.showTotems = show and true or false
    if not InCombatLockdown() then
        self:LoadButtons()
        self:Layout()
    end
end

function TotemBar:ShowingTotems()
    return self.sets.showTotems
end

local tinsert = table.insert

function TotemBar:LoadButtons()
    if InCombatLockdown() then return end
    local buttons = self.buttons

    for i, b in pairs(buttons) do
        b:Free()
        buttons[i] = nil
    end

    if self:IsCallKnown() then
        tinsert(buttons, self:GetCallButton())
    end

    if self:ShowingTotems() then
        for _, totemID in ipairs(TOTEM_PRIORITIES or {1, 2, 3, 4}) do
            tinsert(buttons, self:GetTotemButton(totemID))
        end
    end

    if self:ShowingRecall() and self:IsRecallKnown() then
        tinsert(buttons, self:GetRecallButton())
    end

    self.header:Execute([[ control:ChildUpdate('action', nil) ]])
end

function TotemBar:IsCallKnown()
    return IsSpellKnown(self.callSpell, false)
end

function TotemBar:GetCallButton()
    return self:CreateSpellButton(self.callSpell)
end

function TotemBar:IsRecallKnown()
    return IsSpellKnown(RECALL_SPELL, false)
end

function TotemBar:GetRecallButton()
    return self:CreateSpellButton(RECALL_SPELL)
end

function TotemBar:GetTotemButton(id)
    return self:CreateActionButton(self:GetBaseID() + id)
end

function TotemBar:CreateSpellButton(spellID)
    local b = CleanBars.SpellButton:New(spellID)
    if not InCombatLockdown() then
        b:SetParent(self.header)
    end
    return b
end

function TotemBar:CreateActionButton(actionID)
    local b = CleanBars.ActionButton:New(actionID)
    if not InCombatLockdown() then
        b:SetParent(self.header)
        b:LoadAction()
    end
    return b
end

function TotemBar:AddLayoutPanel(menu)
    local L = ConfigLocale
    local panel = menu:AddLayoutPanel()

    local showRecall = panel:NewCheckButton('ShowTotemRecall', L.ShowTotemRecall)
    showRecall:SetScript('OnClick', function(b)
        self:SetShowRecall(b:GetChecked())
        if panel.colsSlider and panel.colsSlider.OnShow then
            panel.colsSlider:OnShow()
        end
    end)
    showRecall:SetScript('OnShow', function(b)
        b:SetChecked(self:ShowingRecall())
    end)

    local showTotems = panel:NewCheckButton('ShowTotems', L.ShowTotems)
    showTotems:SetScript('OnClick', function(b)
        self:SetShowTotems(b:GetChecked())
        if panel.colsSlider and panel.colsSlider.OnShow then
            panel.colsSlider:OnShow()
        end
    end)
    showTotems:SetScript('OnShow', function(b)
        b:SetChecked(self:ShowingTotems())
    end)
end

function TotemBar:CreateMenu()
    self.menu = CleanBars:NewMenu(self.id)
    self:AddLayoutPanel(self.menu)
    self.menu:AddAdvancedPanel()
end