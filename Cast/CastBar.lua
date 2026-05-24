local MODULE = CleanBars:NewModule('CastingBar')
local C = ConfigLocale
local CastBar, CastingBar
local max = math.max

function MODULE:Load()
    if not self.frame then
        self.frame = CastBar:New()
    end

    CastingBarFrame:UnregisterAllEvents()
    CastingBarFrame:Hide()
    CastingBarFrame:SetAlpha(0)
    CastingBarFrame:EnableMouse(false)
end

function MODULE:Unload()
    if self.frame then
        self.frame:Free()
        self.frame = nil
    end

    CastingBarFrame:SetAlpha(1)
    CastingBarFrame:EnableMouse(true)
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
        width = 250,
        height = 24,
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
end

function CastBar:CreateMenu()
    local menu = CleanBars:NewMenu(self.id)
    local panel = menu:NewPanel(C.Layout or 'Layout')
    
    local time = panel:NewCheckButton('ShowTime', C.ShowTime)
    time:SetScript('OnClick', function(b) self:ToggleText(b:GetChecked()) end)
    time:SetScript('OnShow', function(b) b:SetChecked(self.sets.showText) end)
    
    panel:NewOpacitySlider()
    panel:NewFadeSlider()
    panel:NewScaleSlider()

    local wSlider = panel:NewSlider('Width', C.Width or 'Width', 50, 600, 1)
    wSlider.OnShow = function(s) s:SetValue(s:GetParent().owner.sets.width or 250) end
    wSlider.UpdateValue = function(s, value)
        local f = s:GetParent().owner
        f.sets.width = value
        f:Layout()
    end

    local hSlider = panel:NewSlider('Height', C.Height or 'Height', 10, 100, 1)
    hSlider.OnShow = function(s) s:SetValue(s:GetParent().owner.sets.height or 24) end
    hSlider.UpdateValue = function(s, value)
        local f = s:GetParent().owner
        f.sets.height = value
        f:Layout()
    end

    panel.height = 280

    self.menu = menu
end

function CastBar:Layout()
    local w = self.sets.width or 250
    local h = self.sets.height or 24
    
    self:SetWidth(w)
    self:SetHeight(h)
    
    self.cast:ClearAllPoints()
    self.cast:SetWidth(w)
    self.cast:SetHeight(h)
    self.cast:SetPoint('CENTER', self, 'CENTER')
end

CastingBar = CleanBars:CreateClass('StatusBar')

function CastingBar:New(parent)
    local name = 'CleanBarsCastingBar'
    local f = self:Bind(CreateFrame('StatusBar', name, parent))
    f:Hide()
    f:SetSize(250, 24)
    f:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
    f:SetStatusBarColor(1.0, 0.7, 0.0)

    f.bg = f:CreateTexture(name .. 'Background', 'BACKGROUND')
    f.bg:SetTexture([[Interface\TargetingFrame\UI-StatusBar]])
    f.bg:SetVertexColor(0, 0, 0, 0.5)
    f.bg:SetAllPoints(f)

    f.text = f:CreateFontString(name .. 'Text', 'OVERLAY', 'GameFontHighlight')
    f.text:SetJustifyH('LEFT')
    f.text:SetPoint('LEFT', 6, 0)

    f.time = f:CreateFontString(name .. 'Time', 'OVERLAY', 'GameFontHighlight')
    f.time:SetJustifyH('RIGHT')
    f.time:SetPoint('RIGHT', -6, 0)
    f.time:Hide()

    local font, size = f.text:GetFont()
    f.text:SetFont(font, size, 'OUTLINE')
    f.time:SetFont(font, size, 'OUTLINE')

    f.flash = f:CreateTexture(name .. 'Flash', 'OVERLAY')
    f.flash:SetTexture([[Interface\TargetingFrame\UI-StatusBar]])
    f.flash:SetBlendMode('ADD')
    f.flash:SetAllPoints(f)
    f.flash:SetVertexColor(1, 1, 1, 0.5)
    f.flash:Hide()

    f.borderOverlay = CreateFrame('Frame', name .. 'BorderOverlay', f)
    f.borderOverlay:SetPoint('TOPLEFT', -3, 3)
    f.borderOverlay:SetPoint('BOTTOMRIGHT', 3, -3)
    f.borderOverlay:SetBackdrop({
        edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
        edgeSize = 12,
    })
    f.borderOverlay:SetBackdropBorderColor(1, 1, 1, 0.5)
    f.borderOverlay:SetFrameLevel(f:GetFrameLevel() + 2)

    f.icon = f:CreateTexture(name .. 'Icon', 'BACKGROUND')
    f.icon:Hide()
    f.border = f:CreateTexture(name .. 'Border', 'ARTWORK')
    f.border:Hide()
    f.borderShield = f:CreateTexture(name .. 'BorderShield', 'ARTWORK')
    f.borderShield:Hide()
    f.shield = f:CreateTexture(name .. 'Shield', 'ARTWORK')
    f.shield:Hide()
    f.spark = f:CreateTexture(name .. 'Spark', 'OVERLAY')
    f.spark:Hide()

    f:SetScript('OnUpdate', f.OnUpdate)
    f:SetScript('OnEvent', f.OnEvent)
    f:SetScript('OnShow', CastingBarFrame_OnShow)

    CastingBarFrame_OnLoad(f, 'player', true, false)
    
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
            self:OnUpdate(0)
        end
        self:UpdateColor()
    end
end

function CastingBar:OnUpdate(elapsed)
    CastingBarFrame_OnUpdate(self, elapsed)
    if self.casting then
        self.time:SetFormattedText('%.1f', self.maxValue - self.value)
    elseif self.channeling then
        self.time:SetFormattedText('%.1f', self.value)
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
        if InCombatLockdown() then
            self:SetChecked(CleanBars.db.global.modules.CastingBar ~= false)
            CleanBars:Print("Can't change settings in combat.")
            return
        end

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