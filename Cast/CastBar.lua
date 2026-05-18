local MODULE = CleanBars:NewModule('CastingBar')
local C = ConfigLocale
local CastBar, CastingBar
local max = math.max

function MODULE:Load()
    if not self.frame then
        self.frame = CastBar:New()
    end

    CastingBarFrame:UnregisterAllEvents()
    CastingBarFrame.Show = CastingBarFrame.Hide
    CastingBarFrame:Hide()
end

function MODULE:Unload()
    if self.frame then
        self.frame:Free()
        self.frame = nil
    end

    CastingBarFrame.Show = nil
    CastingBarFrame_OnLoad(CastingBarFrame, 'player', true)
end

CastBar = CleanBars:CreateClass('Frame', CleanBars.Frame)

function CastBar:New()
    local f = self.super.New(self, 'cast')
    f:SetFrameStrata('HIGH')
    if not f.cast then
        f.cast = CastingBar:New(f)
        f.header:SetParent(nil)
        f.header:ClearAllPoints()
        f:SetWidth(240) 
        f:SetHeight(24)
    end
    f:UpdateText()
    f:Layout()
    return f
end

function CastBar:GetDefaults()
    return {
        point = 'CENTER',
        x = 0,
        y = 30,
        showText = true,
    }
end

function CastBar:ToggleText(enable)
    self.sets.showText = enable or nil
    self:UpdateText()
end

function CastBar:UpdateText()
    if self.sets.showText then
        self.cast.time:Show()
    else
        self.cast.time:Hide()
    end
    self.cast:AdjustWidth()
end

function CastBar:CreateMenu()
    local menu = CleanBars:NewMenu(self.id)
    local panel = menu:NewPanel(ConfigLocale.Layout)
    local time = panel:NewCheckButton('ShowTime', C.ShowTime)
    time:SetScript('OnClick', function(b) self:ToggleText(b:GetChecked()) end)
    time:SetScript('OnShow', function(b) b:SetChecked(self.sets.showText) end)
    panel:NewOpacitySlider()
    panel:NewFadeSlider()
    panel:NewScaleSlider()
    panel:NewPaddingSlider()
    self.menu = menu
end

function CastBar:Layout()
    self:SetWidth(max(self.cast:GetWidth() + 4 + self:GetPadding()*2, 8))
    self:SetHeight(max(24 + self:GetPadding()*2, 8))
end

CastingBar = CleanBars:CreateClass('StatusBar')
local BORDER_SCALE = 197/150 
local TEXT_PADDING = 18

function CastingBar:New(parent)
    local f = self:Bind(CreateFrame('StatusBar', 'CleanBarsCastingBar', parent, 'CleanBarsCastingBarTemplate'))
    f:SetPoint('CENTER')
    local name = f:GetName()
    local _G = getfenv(0)
    f.time = _G[name .. 'Time']
    f.text = _G[name .. 'Text']

    local font, size = f.text:GetFont()
    f.text:SetFont(font, size, 'OUTLINE')
    f.time:SetFont(font, size, 'OUTLINE')

    f.borderTexture = _G[name .. 'Border']
    f.flashTexture = _G[name .. 'Flash']
    f.normalWidth = f:GetWidth()
    f:SetScript('OnUpdate', f.OnUpdate)
    f:SetScript('OnEvent', f.OnEvent)
    return f
end

function CastingBar:OnEvent(event, ...)
    CastingBarFrame_OnEvent(self, event, ...)
    local unit, spell = ...
    if unit == self.unit then
        if event == 'UNIT_SPELLCAST_FAILED' or event == 'UNIT_SPELLCAST_INTERRUPTED' then
            self.failed = true
        elseif event == 'UNIT_SPELLCAST_START' or event == 'UNIT_SPELLCAST_CHANNEL_START' then
            self.failed = nil
        end
        self:UpdateColor()
    end
end

function CastingBar:OnUpdate(elapsed)
    CastingBarFrame_OnUpdate(self, elapsed)
    if self.casting then
        self.time:SetFormattedText('%.1f', self.maxValue - self.value)
        self:AdjustWidth()
    elseif self.channeling then
        self.time:SetFormattedText('%.1f', self.value)
        self:AdjustWidth()
    end
end

function CastingBar:AdjustWidth()
    local textWidth = self.text:GetStringWidth() + TEXT_PADDING
    local timeWidth = (self.time:IsShown() and (self.time:GetStringWidth() + 4) * 2) or 0
    local width = textWidth + timeWidth
    local diff = width - self.normalWidth
    if diff > 0 then
        diff = width - self:GetWidth()
    else
        diff = self.normalWidth - self:GetWidth()
    end
    if diff ~= 0 then
        local newWidth = self:GetWidth() + diff
        self:SetWidth(newWidth)
        self.borderTexture:SetWidth(newWidth * BORDER_SCALE)
        self.flashTexture:SetWidth(newWidth * BORDER_SCALE)
        self:GetParent():Layout()
    end
end

function CastingBar:UpdateColor()
    if self.failed then
        self:SetStatusBarColor(0.86, 0.08, 0.24)
    else
        local _, class = UnitClass('player')
        local color = RAID_CLASS_COLORS[class]
        if color then
            self:SetStatusBarColor(color.r, color.g, color.b)
        else
            self:SetStatusBarColor(1, 0.7, 0)
        end
    end
end

do
    local parentMenuName = CleanBars.Options.name
    local castPanel = CleanBars.Options:New('CleanBarsCastOptions', C.CastBarTitle, C.CastBarDesc, parentMenuName)
    local enableCastCB = castPanel:NewCheckButton('EnableCastingBarMod', C.EnableCastMod)
    enableCastCB:SetPoint('TOPLEFT', 16, -80)
    
    enableCastCB:SetScript('OnShow', function(self)
        self:SetChecked(CleanBars.db.global.modules.CastingBar ~= false)
    end)
    
    enableCastCB:SetScript('OnClick', function(self)
        local checked = self:GetChecked() and true or false
        CleanBars.db.global.modules.CastingBar = checked
        
        if checked then
            MODULE:Load()
            if MODULE.frame and MODULE.frame.Reanchor then MODULE.frame:Reanchor() end
        else
            MODULE:Unload()
        end
    end)
end