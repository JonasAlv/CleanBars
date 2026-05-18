local Drag = CleanBars:CreateClass('Button')
CleanBars.DragFrame = Drag

local L = Locale
local ceil = math.ceil
local min = math.min
local max = math.max

function Drag:New(owner)
    local f = self:Bind(CreateFrame('Button', nil, UIParent))
    f.owner = owner

    f:EnableMouseWheel(true)
    f:SetClampedToScreen(true)
    f:SetFrameStrata(owner:GetFrameStrata())
    f:SetAllPoints(owner)
    f:SetFrameLevel(owner:GetFrameLevel() + 5)

    local bg = f:CreateTexture(nil, 'BACKGROUND')
    bg:SetTexture(1, 1, 1, 0.4)
    bg:SetAllPoints(f)
    f:SetNormalTexture(bg)

    local t = f:CreateTexture(nil, 'BACKGROUND')
    t:SetTexture(0.2, 0.3, 0.4, 0.5)
    t:SetAllPoints(f)
    f:SetHighlightTexture(t)

    f:SetNormalFontObject('GameFontNormalLarge')
    f:SetText(owner.id)

    f:RegisterForClicks('AnyUp')
    f:RegisterForDrag('LeftButton')
    f:SetScript('OnMouseDown', self.StartMoving)
    f:SetScript('OnMouseUp', self.StopMoving)
    f:SetScript('OnMouseWheel', self.OnMouseWheel)
    f:SetScript('OnClick', self.OnClick)
    f:SetScript('OnEnter', self.OnEnter)
    f:SetScript('OnLeave', self.OnLeave)
    f:Hide()

    return f
end

function Drag:OnEnter()
    GameTooltip:SetOwner(self, 'ANCHOR_BOTTOMLEFT')
    
    local text = tostring(self:GetText() or '')
    GameTooltip:SetText(format('Bar: %s', text:gsub('^%l', string.upper)), 1, 1, 1)
    
    local tooltipText = self.owner:GetTooltipText()
    if tooltipText then
        GameTooltip:AddLine(tooltipText, nil, nil, nil, 1)
    end

    if self.owner.ShowMenu then
        GameTooltip:AddLine(L.ShowConfig)
    end

    if self.owner:IsShown() then
        GameTooltip:AddLine(L.HideBar)
    else
        GameTooltip:AddLine(L.ShowBar)
    end

    GameTooltip:AddLine(format(L.SetAlpha, ceil(self.owner:GetFrameAlpha() * 100)))
    GameTooltip:Show()
end

function Drag:OnLeave()
    GameTooltip:Hide()
end

function Drag:StartMoving(button)
    if button == 'LeftButton' then
        self.isMoving = true
        self.owner:StartMoving()

        if GameTooltip:IsOwned(self) then
            GameTooltip:Hide()
        end
    end
end

function Drag:StopMoving()
    if self.isMoving then
        self.isMoving = nil
        self.owner:StopMovingOrSizing()
        self.owner:Stick()
        self:OnEnter()
    end
end

function Drag:OnMouseWheel(arg1)
    local newAlpha = min(max(self.owner:GetAlpha() + (arg1 * 0.1), 0), 1)
    if newAlpha ~= self.owner:GetAlpha() then
        self.owner:SetFrameAlpha(newAlpha)
        self:OnEnter()
    end
end

function Drag:OnClick(button)
    if button == 'RightButton' then
        if IsShiftKeyDown() then
            self.owner:ToggleFrame()
        else
            self.owner:ShowMenu()
        end
    elseif button == 'MiddleButton' then
        self.owner:ToggleFrame()
    end
    self:OnEnter()
end

function Drag:UpdateColor()
    local normal = self:GetNormalTexture()
    if not normal then return end

    if self.owner:IsShown() then
        if self.owner:GetAnchor() then
            normal:SetTexture(0, 0.2, 0.2, 0.4)
        else
            normal:SetTexture(0, 0.5, 0.7, 0.4)
        end
    else
        if self.owner:GetAnchor() then
            normal:SetTexture(0.1, 0.1, 0.1, 0.4)
        else
            normal:SetTexture(0.5, 0.5, 0.5, 0.4)
        end
    end
end