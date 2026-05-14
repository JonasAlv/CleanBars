local L = CleanBarsLocale

local MinimapButton = CreateFrame('Button', 'CleanBarsMinimapButton', Minimap)
CleanBars.Minimap = MinimapButton

function MinimapButton:Load()
	local BG_COLOR = {r = 0, g = 0, b = 0, a = 1}
	local TEXT_COLOR = {r = 1, g = 1, b = 1}
	local TEXT_LABEL = "CB"

	self:SetSize(34, 34)
	self:SetFrameStrata('MEDIUM')
	self:SetClampedToScreen(true)
	self:SetMovable(true)
	self:RegisterForDrag('LeftButton')
	self:RegisterForClicks('LeftButtonUp', 'RightButtonUp')

	local CleanBarsMinimapBG = self:CreateTexture(nil, 'BACKGROUND')
	CleanBarsMinimapBG:SetTexture('Interface\\Minimap\\UI-Minimap-Background')
	CleanBarsMinimapBG:SetVertexColor(BG_COLOR.r, BG_COLOR.g, BG_COLOR.b, BG_COLOR.a)
	CleanBarsMinimapBG:SetSize(21, 21)
	CleanBarsMinimapBG:SetPoint('CENTER', 0, 0)

	local CleanBarsMinimapLabel = self:CreateFontString(nil, 'OVERLAY')
	CleanBarsMinimapLabel:SetFont('Fonts\\FRIZQT__.TTF', 9, 'OUTLINE')
	CleanBarsMinimapLabel:SetPoint('CENTER', 0, 0)
	CleanBarsMinimapLabel:SetText(TEXT_LABEL)
	CleanBarsMinimapLabel:SetTextColor(TEXT_COLOR.r, TEXT_COLOR.g, TEXT_COLOR.b)

	local CleanBarsMinimapBorder = self:CreateTexture(nil, 'OVERLAY')
	CleanBarsMinimapBorder:SetTexture('Interface\\Minimap\\MiniMap-TrackingBorder')
	CleanBarsMinimapBorder:SetSize(52, 52)
	CleanBarsMinimapBorder:SetPoint('TOPLEFT', 0, 0)
	self:SetHighlightTexture('Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight')

	self:SetScript('OnEnter', self.OnEnter)
	self:SetScript('OnLeave', self.OnLeave)
	self:SetScript('OnClick', self.OnClick)
	self:SetScript('OnDragStart', self.OnDragStart)
	self:SetScript('OnDragStop', self.OnDragStop)
end

function MinimapButton:OnClick(button)
	if button == 'LeftButton' then
		if IsShiftKeyDown() then
			CleanBars:ToggleBindingMode()
		else
			CleanBars:ToggleLockedFrames()
		end
	elseif button == 'RightButton' then
		CleanBars:ShowOptions()
	end
	self:OnEnter()
end

function MinimapButton:OnEnter()
	if not self.dragging then
		GameTooltip:SetOwner(self, 'ANCHOR_TOPRIGHT')
		GameTooltip:SetText('CleanBars', 1, 1, 1)

		if CleanBars:Locked() then
			GameTooltip:AddLine(L.ConfigEnterTip)
		else
			GameTooltip:AddLine(L.ConfigExitTip)
		end

		local KB = LibStub('LibKeyBound-1.0', true)
		if KB then
			if KB:IsShown() then
				GameTooltip:AddLine(L.BindingExitTip)
			else
				GameTooltip:AddLine(L.BindingEnterTip)
			end
		end

		local enabled = select(4, GetAddOnInfo('CleanBarsConfig'))
		if enabled then
			GameTooltip:AddLine(L.ShowOptionsTip)
		end
		GameTooltip:Show()
	end
end

function MinimapButton:OnLeave()
	GameTooltip:Hide()
end

function MinimapButton:OnDragStart()
	self.dragging = true
	self:LockHighlight()
	self:SetScript('OnUpdate', self.OnUpdate)
	GameTooltip:Hide()
end

function MinimapButton:OnDragStop()
	self.dragging = nil
	self:SetScript('OnUpdate', nil)
	self:UnlockHighlight()
end

function MinimapButton:OnUpdate()
	local mx, my = Minimap:GetCenter()
	local px, py = GetCursorPosition()
	local scale = Minimap:GetEffectiveScale()

	px, py = px / scale, py / scale

	CleanBars:SetMinimapButtonPosition(math.deg(math.atan2(py - my, px - mx)) % 360)
	self:UpdatePosition()
end

function MinimapButton:UpdatePosition()
	local angle = math.rad(CleanBars:GetMinimapButtonPosition() or random(0, 360))
	local cos = math.cos(angle)
	local sin = math.sin(angle)
	local minimapShape = GetMinimapShape and GetMinimapShape() or 'ROUND'

	local round = false
	if minimapShape == 'ROUND' then
		round = true
	elseif minimapShape == 'SQUARE' then
		round = false
	elseif minimapShape == 'CORNER-TOPRIGHT' then
		round = not(cos < 0 or sin < 0)
	elseif minimapShape == 'CORNER-TOPLEFT' then
		round = not(cos > 0 or sin < 0)
	elseif minimapShape == 'CORNER-BOTTOMRIGHT' then
		round = not(cos < 0 or sin > 0)
	elseif minimapShape == 'CORNER-BOTTOMLEFT' then
		round = not(cos > 0 or sin > 0)
	elseif minimapShape == 'SIDE-LEFT' then
		round = cos <= 0
	elseif minimapShape == 'SIDE-RIGHT' then
		round = cos >= 0
	elseif minimapShape == 'SIDE-TOP' then
		round = sin <= 0
	elseif minimapShape == 'SIDE-BOTTOM' then
		round = sin >= 0
	elseif minimapShape == 'TRICORNER-TOPRIGHT' then
		round = not(cos < 0 and sin > 0)
	elseif minimapShape == 'TRICORNER-TOPLEFT' then
		round = not(cos > 0 and sin > 0)
	elseif minimapShape == 'TRICORNER-BOTTOMRIGHT' then
		round = not(cos < 0 and sin < 0)
	elseif minimapShape == 'TRICORNER-BOTTOMLEFT' then
		round = not(cos > 0 and sin < 0)
	end

	local x, y
	if round then
		x = cos*80
		y = sin*80
	else
		x = math.max(-82, math.min(110*cos, 84))
		y = math.max(-86, math.min(110*sin, 82))
	end

	self:SetPoint('CENTER', x, y)
end

MinimapButton:Load()