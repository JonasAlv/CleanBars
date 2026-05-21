local XP_FORMAT = '%s / %s [%s%%]'
local REST_FORMAT = '%s / %s (+%s) [%s%%]'
local REP_FORMAT = '%s:  %s / %s (%s)'
local L = XPLocale
local C = ConfigLocale
local _G = getfenv(0)
local max = math.max

local function comma_value(n)
    local left,num,right = string.match(tostring(n), '^([^%d]*%d)(%d*)(.-)$')
    return left..(num:reverse():gsub('(%d%d%d)','%1,'):reverse())..right
end

local function IsMaxLevel()
    return UnitLevel('player') == MAX_PLAYER_LEVEL or UnitXPMax('player') == 0
end

local MODULE = CleanBars:NewModule('xp')
local xpBar

function MODULE:Load()
    if not self.frame then
        self.frame = xpBar:New()
        self.frame:SetFrameStrata('BACKGROUND')
    end
end

function MODULE:Unload()
    if self.frame then
        self.frame:Free()
        self.frame = nil
    end
end

xpBar = CleanBars:CreateClass('Frame', CleanBars.Frame)

function xpBar:New()
    local f = self.super.New(self, 'xp')
    if not f.value then f:Load() end
    f:Layout()
    f:UpdateTexture()
    f:UpdateWatch()
    f:UpdateTextShown()
    return f
end

function xpBar:GetDefaults()
    return {
        alwaysShowText = true,
        point = 'TOP',
        width = 0.75,
        height = 14,
        y = -32,
        x = 0,
        texture = 'blizzard'
    }
end

function xpBar:Load()
    local bg = self:CreateTexture(nil, 'BACKGROUND')
    bg:SetAllPoints(self)
    if bg.SetHorizTile then bg:SetHorizTile(false) end
    self.bg = bg
    local rest = CreateFrame('StatusBar', nil, self)
    rest:EnableMouse(false)
    rest:SetAllPoints(self)
    self.rest = rest
    local value = CreateFrame('StatusBar', nil, rest)
    value:EnableMouse(false)
    value:SetAllPoints(self)
    self.value = value

    local click = CreateFrame('Button', nil, value)
    click:SetScript('OnClick', function(_, ...) self:OnClick(...) end)
    click:SetScript('OnEnter', function(_, ...) self:OnEnter(...) end)
    click:SetScript('OnLeave', function(_, ...) self:OnLeave(...) end)
    click:RegisterForClicks('anyUp')
    click:SetAllPoints(self)
    self.click = click

    self.ticks = {}
    for i = 1, 9 do
        local tick = click:CreateTexture(nil, 'BACKGROUND')
        tick:SetTexture('Interface\\ChatFrame\\ChatFrameBackground')
        tick:SetVertexColor(0, 0, 0, 0.9)
        tick:SetWidth(1)
        self.ticks[i] = tick
    end

    local text = click:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
    text:SetPoint('CENTER')
    self.text = text
end

function xpBar:OnClick(button)
    if button == 'RightButton' then
        if FFF_ReputationWatchBar_OnClick then
            self:SetAlwaysShowXP(false)
            FFF_ReputationWatchBar_OnClick(self, button)        
        else
            ToggleCharacter("ReputationFrame")
        end
    else
        if not IsMaxLevel() and GetWatchedFactionInfo() then
            self:SetAlwaysShowXP(not self.sets.alwaysShowXP)
        end
    end
    self:UpdateRepWatcherTooltip()
end

function xpBar:OnEnter()
    self:UpdateTextShown()
    if (FFF_ReputationWatchBar_OnEnter and self:ShouldWatchFaction()) then
        FFF_ReputationWatchBar_OnEnter(self)
    end
end

function xpBar:OnLeave()
    self:UpdateTextShown()
    if (FFF_ReputationWatchBar_OnLeave) then
        FFF_ReputationWatchBar_OnLeave(self)
    end
end

function xpBar:UpdateRepWatcherTooltip()
    if GameTooltip:IsOwned(self) and self:ShouldWatchFaction() then
        if FFF_ReputationWatchBar_OnEnter then FFF_ReputationWatchBar_OnEnter(self) end
    else
        if FFF_ReputationWatchBar_OnLeave then FFF_ReputationWatchBar_OnLeave(self) end
    end
end

function xpBar:UpdateWatch()
    if IsMaxLevel() and not GetWatchedFactionInfo() then
        self:Hide()
        self:UnregisterAllEvents()
        self:RegisterEvent('UPDATE_FACTION')
        self:SetScript('OnEvent', function(_, event)
            if event == 'UPDATE_FACTION' then self:UpdateWatch() end
        end)
        return
    else
        self:Show()
    end

    if self:ShouldWatchFaction() then 
        self:WatchReputation() 
    else 
        self:WatchExperience() 
    end
end

function xpBar:ShouldWatchFaction()
    if not GetWatchedFactionInfo() then return false end
    if IsMaxLevel() then return true end
    return not self.sets.alwaysShowXP
end

function xpBar:WatchExperience()
    self:UnregisterAllEvents()
    self:SetScript('OnEvent', self.OnXPEvent)
    self:RegisterEvent('UPDATE_FACTION')
    self:RegisterEvent('UPDATE_EXHAUSTION')
    self:RegisterEvent('PLAYER_XP_UPDATE')
    self:RegisterEvent('PLAYER_LEVEL_UP')
    self:RegisterEvent('PLAYER_LOGIN')
    self.rest:SetStatusBarColor(0.25, 0.25, 1)
    self.value:SetStatusBarColor(0.6, 0, 0.6)
    self.bg:SetVertexColor(0, 0, 0, 0.5)
    self:UpdateExperience()
end

function xpBar:OnXPEvent(event)
    if event == 'UPDATE_FACTION' or event == 'PLAYER_LEVEL_UP' then
        self:UpdateWatch()
    else
        self:UpdateExperience()
    end
end

function xpBar:UpdateExperience()
    local value = UnitXP('player') or 0
    local maxXP = UnitXPMax('player') or 1
    if maxXP == 0 then maxXP = 1 end
    local pct = math.floor((value / maxXP) * 100 + 0.5)
    
    self.value:SetMinMaxValues(0, maxXP)
    self.value:SetValue(value)
    
    local rest = GetXPExhaustion()
    self.rest:SetMinMaxValues(0, maxXP)
    
    if rest then
        self.rest:SetValue(value + rest)
        self.text:SetFormattedText(REST_FORMAT, comma_value(value), comma_value(maxXP), comma_value(rest), pct)
    else
        self.rest:SetValue(0)
        self.text:SetFormattedText(XP_FORMAT, comma_value(value), comma_value(maxXP), pct)
    end
end

function xpBar:WatchReputation()
    self:UnregisterAllEvents()
    self:SetScript('OnEvent', self.OnRepEvent)
    self:RegisterEvent('UPDATE_FACTION')
    self:RegisterEvent('PLAYER_LEVEL_UP')
    self.rest:SetValue(0)
    self.rest:SetStatusBarColor(0, 0, 0, 0)
    self:UpdateReputation()
end

function xpBar:OnRepEvent(event)
    if event == 'UPDATE_FACTION' or event == 'PLAYER_LEVEL_UP' then
        self:UpdateWatch()
    else
        self:UpdateReputation()
    end
end

function xpBar:UpdateReputation()
    local name, reaction, min, max, value = GetWatchedFactionInfo()
    max = max - min
    value = value - min
    local color = FACTION_BAR_COLORS[reaction]
    self.value:SetStatusBarColor(color.r, color.g, color.b)
    self.bg:SetVertexColor(0, 0, 0, 0.5) -- Clean Blizzard transparent background
    self.value:SetMinMaxValues(0, max)
    self.value:SetValue(value)
    local repLevel = _G['FACTION_STANDING_LABEL' .. reaction]
    self.text:SetFormattedText(REP_FORMAT, name, comma_value(value), comma_value(max), repLevel)
end

function xpBar:Layout()
    local width = GetScreenWidth() * self.sets.width
    self:SetWidth(width)
    self:SetHeight(self.sets.height)

    if self.ticks then
        local sectionWidth = width / 10
        for i = 1, 9 do
            local tick = self.ticks[i]
            tick:ClearAllPoints()
            tick:SetPoint('TOP', self, 'TOPLEFT', sectionWidth * i, 0)
            tick:SetPoint('BOTTOM', self, 'BOTTOMLEFT', sectionWidth * i, 0)
        end
    end
end

function xpBar:SetTexture(texture)
    self.sets.texture = texture
    self:UpdateTexture()
end

function xpBar:UpdateTexture()
    local LSM = LibStub('LibSharedMedia-3.0', true)
    local texture = (LSM and LSM:Fetch('statusbar', self.sets.texture)) or DEFAULT_STATUSBAR_TEXTURE
    self.value:SetStatusBarTexture(texture)
    if self.value:GetStatusBarTexture().SetHorizTile then self.value:GetStatusBarTexture():SetHorizTile(false) end
    self.rest:SetStatusBarTexture(texture)
    if self.rest:GetStatusBarTexture().SetHorizTile then self.rest:GetStatusBarTexture():SetHorizTile(false) end
    self.bg:SetTexture(texture)
end

function xpBar:SetAlwaysShowXP(enable)
    self.sets.alwaysShowXP = enable
    self:UpdateWatch()
end

if xpBar.IsMouseOver then
    function xpBar:UpdateTextShown()
        if self:IsMouseOver() or self.sets.alwaysShowText then self.text:Show() else self.text:Hide() end
    end
else
    function xpBar:UpdateTextShown()
        if MouseIsOver(self) or self.sets.alwaysShowText then self.text:Show() else self.text:Hide() end
    end
end

function xpBar:ToggleText(enable)
    self.sets.alwaysShowText = enable or nil
    self:UpdateTextShown()
end

local function CreateWidthSlider(p)
    local s = p:NewSlider('Width', L.Width, 1, 100, 1)
    s.OnShow = function(self) self:SetValue(self:GetParent().owner.sets.width * 100) end
    s.UpdateValue = function(self, value)
        local f = self:GetParent().owner
        f.sets.width = value/100
        f:Layout()
    end
end

local function CreateHeightSlider(p)
    local s = p:NewSlider('Height', L.Height, 1, 128, 1)
    s.OnShow = function(self) self:SetValue(self:GetParent().owner.sets.height) end
    s.UpdateValue = function(self, value)
        local f = self:GetParent().owner
        f.sets.height = value
        f:Layout()
    end
end

local function AddLayoutPanel(menu)
    local p = menu:NewPanel(ConfigLocale.Layout)
    p:NewOpacitySlider()
    p:NewFadeSlider()
    p:NewScaleSlider()
    CreateHeightSlider(p)
    CreateWidthSlider(p)
    local showText = p:NewCheckButton('AlwaysShowText', L.AlwaysShowText)
    showText:SetScript('OnClick', function(self) self:GetParent().owner:ToggleText(self:GetChecked()) end)
    showText:SetScript('OnShow', function(self) self:SetChecked(self:GetParent().owner.sets.alwaysShowText) end)
    local showXP = p:NewCheckButton('AlwaysShowXP', L.AlwaysShowXP)
    showXP:SetScript('OnClick', function(self) self:GetParent().owner:SetAlwaysShowXP(self:GetChecked()) end)
    showXP:SetScript('OnShow', function(self) self:SetChecked(self:GetParent().owner.sets.alwaysShowXP) end)
end

local NUM_ITEMS = 9
local width, height, offset = 140, 20, 2
local function TextureButton_OnClick(self)
    MODULE.frame:SetTexture(self:GetText())
    self:GetParent():UpdateList()
end

local function TextureButton_OnMouseWheel(self, direction)
    local scrollBar = _G[self:GetParent().scroll:GetName() .. 'ScrollBar']
    scrollBar:SetValue(scrollBar:GetValue() - direction * (scrollBar:GetHeight()/2))
    parent:UpdateList()
end

local function TextureButton_Create(name, parent)
    local button = CreateFrame('Button', name, parent)
    button:SetWidth(width)
    button:SetHeight(height)
    button.bg = button:CreateTexture()
    button.bg:SetAllPoints(button)
    local r, g, b = max(random(), 0.2), max(random(), 0.2), max(random(), 0.2)
    button.bg:SetVertexColor(r, g, b)
    button:EnableMouseWheel(true)
    button:SetScript('OnClick', TextureButton_OnClick)
    button:SetScript('OnMouseWheel', TextureButton_OnMouseWheel)
    button:SetNormalFontObject('GameFontNormalLeft')
    button:SetHighlightFontObject('GameFontHighlightLeft')
    return button
end

local function Panel_UpdateList(self)
    local SML = LibStub('LibSharedMedia-3.0')
    local textures = LibStub('LibSharedMedia-3.0'):List('statusbar')
    local currentTexture = MODULE.frame.sets.texture
    local scroll = self.scroll
    FauxScrollFrame_Update(scroll, #textures, #self.buttons, height + offset)
    for i,button in pairs(self.buttons) do
        local index = i + scroll.offset
        if index <= #textures then
            button:SetText(textures[index])
            button.bg:SetTexture(SML:Fetch('statusbar', textures[index]))
            button:Show()
        else
            button:Hide()
        end
    end
end

local function AddTexturePanel(menu)
    local p = menu:NewPanel(L.Texture)
    p.UpdateList = Panel_UpdateList
    p:SetScript('OnShow', function() p:UpdateList() end)
    p.textures = LibStub('LibSharedMedia-3.0'):List('statusbar')
    local name = p:GetName()
    local scroll = CreateFrame('ScrollFrame', name .. 'ScrollFrame', p, 'FauxScrollFrameTemplate')
    scroll:SetScript('OnVerticalScroll', function(self, arg1) FauxScrollFrame_OnVerticalScroll(self, arg1, height + offset, function() p:UpdateList() end) end)
    scroll:SetScript('OnShow', function() p.buttons[1]:SetWidth(width) end)
    scroll:SetScript('OnHide', function() p.buttons[1]:SetWidth(width + 20) end)
    scroll:SetPoint('TOPLEFT', 8, 0)
    scroll:SetPoint('BOTTOMRIGHT', -24, 2)
    p.scroll = scroll
    p.buttons = {}
    for i = 1, NUM_ITEMS do
        local b = TextureButton_Create(name .. i, p)
        if i == 1 then
            b:SetPoint('TOPLEFT', 4, 0)
        else
            b:SetPoint('TOPLEFT', name .. i-1, 'BOTTOMLEFT', 0, -offset)
            b:SetPoint('TOPRIGHT', name .. i-1, 'BOTTOMRIGHT', 0, -offset)
        end
        p.buttons[i] = b
    end
    p.height = 200
end

function xpBar:CreateMenu()
    local menu = CleanBars:NewMenu(self.id)
    AddLayoutPanel(menu)
    AddTexturePanel(menu)
    self.menu = menu
end

do
    local parentMenuName = CleanBars.Options.name
    local xpPanel = CleanBars.Options:New('CleanBarsXpOptions', C.XpBarTitle, C.XpBarDesc, parentMenuName)
    local enableXpCB = xpPanel:NewCheckButton('EnableXPMod', C.EnableXpMod)
    enableXpCB:SetPoint('TOPLEFT', 16, -80)
    
    enableXpCB:SetScript('OnShow', function(self)
        self:SetChecked(CleanBars.db.global.modules.xp ~= false)
    end)
    
    enableXpCB:SetScript('OnClick', function(self)
        if InCombatLockdown() then
            self:SetChecked(CleanBars.db.global.modules.xp ~= false)
            CleanBars:Print("Can't change settings in combat.")
            return
        end

        local checked = self:GetChecked() and true or false
        CleanBars.db.global.modules.xp = checked
        
        if checked then
            MODULE:Load()
            if MODULE.frame and MODULE.frame.Reanchor then MODULE.frame:Reanchor() end
        else
            MODULE:Unload()
        end
    end)
end