local VehicleBar = CleanBars:CreateClass('Frame', CleanBars.Frame)
CleanBars.VehicleBar  = VehicleBar

local L = Locale
local InCombatLockdown = InCombatLockdown
local unpack = unpack
local _G = getfenv(0)

local buttons = {VehicleMenuBarLeaveButton, VehicleMenuBarPitchUpButton, VehicleMenuBarPitchDownButton}

function VehicleBar:New()
    local f = self.super.New(self, 'vehicle', L.TipVehicleBar)
    f:SkinButtons()
    f:LoadButtons()
    f:Layout()
    f:SetScript('OnEvent', f.OnEvent)
    f:RegisterEvent('UNIT_ENTERED_VEHICLE')
    f:RegisterEvent('UNIT_ENTERING_VEHICLE')
    f:RegisterEvent('PLAYER_REGEN_ENABLED')

    return f
end

function VehicleBar:OnEvent(event, arg1)
    if event == 'UNIT_ENTERED_VEHICLE' or event == 'PLAYER_REGEN_ENABLED' then
        if arg1 == 'player' or event == 'PLAYER_REGEN_ENABLED' then
            self:UpdateButtonVisibility()
        end
    end
end

function VehicleBar:UpdateButtonVisibility()
    local up = _G['VehicleMenuBarPitchUpButton']
    local down = _G['VehicleMenuBarPitchDownButton']
    local leave = _G['VehicleMenuBarLeaveButton']

    if IsVehicleAimAngleAdjustable() then
        if not InCombatLockdown() then
            up:Show()
            down:Show()
        end
        up:SetAlpha(1)
        down:SetAlpha(1)
    else
        if not InCombatLockdown() then
            up:Hide()
            down:Hide()
        end
        up:SetAlpha(0)
        down:SetAlpha(0)
    end

    if CanExitVehicle() then
        if not InCombatLockdown() then
            leave:Show()
        end
        leave:SetAlpha(1)
    else
        if not InCombatLockdown() then
            leave:Hide()
        end
        leave:SetAlpha(0)
    end
end

function VehicleBar:SkinButtons()
    self:ApplySkin('PitchUpButton')
    self:ApplySkin('PitchDownButton')
    self:ApplySkin('LeaveButton')
end

function VehicleBar:ApplySkin(frameName)
    local skin = self:GetSkinData(frameName)
    local frame = _G['VehicleMenuBar' .. frameName]
    frame:SetWidth(30)
    frame:SetHeight(30)

    if skin.normalTexture then
        frame:GetNormalTexture():SetTexture(skin.normalTexture)
        frame:GetNormalTexture():SetTexCoord(unpack(skin.normalTexCoord))
    end

    if skin.pushedTexture then
        frame:GetPushedTexture():SetTexture(skin.pushedTexture)
        frame:GetPushedTexture():SetTexCoord(unpack(skin.pushedTexCoord))
    end

    if skin.texture then
        frame:SetTexture(skin.texture)
        frame:SetTexCoord(unpack(skin.texCoord))
    end
end

function VehicleBar:GetSkinData(frameName)
    if frameName == 'PitchUpButton' then
        return {    
            height = 36,
            width = 38,
            point = "BOTTOMLEFT",
            xOfs = 146,
            yOfs = 41,
            normalTexture = [[Interface\Vehicles\UI-Vehicles-Button-Pitch-Up]],
            normalTexCoord = { 0.21875, 0.765625, 0.234375, 0.78125 },
            pushedTexture = [[Interface\Vehicles\UI-Vehicles-Button-Pitch-Down]],
            pushedTexCoord = { 0.21875, 0.765625, 0.234375, 0.78125 },
            pitchHidden = 1,
        }
    elseif frameName == 'PitchDownButton' then
        return {    
            height = 36,
            width = 38,
            point = "BOTTOMLEFT",
            xOfs = 146,
            yOfs = 3,
            normalTexture = [[Interface\Vehicles\UI-Vehicles-Button-PitchDown-Up]],
            normalTexCoord = { 0.21875, 0.765625, 0.234375, 0.78125 },
            pushedTexture = [[Interface\Vehicles\UI-Vehicles-Button-PitchDown-Down]],
            pushedTexCoord = { 0.21875, 0.765625, 0.234375, 0.78125 },
            pitchHidden = 1,
        }
    elseif frameName == 'LeaveButton' then
        return {    
            height = 47,
            width = 50,
            point = "BOTTOMRIGHT",
            xOfs = -148,
            yOfs = 18,
            normalTexture = [[Interface\Vehicles\UI-Vehicles-Button-Exit-Up]],
            normalTexCoord = { 0.140625, 0.859375, 0.140625, 0.859375 },
            pushedTexture = [[Interface\Vehicles\UI-Vehicles-Button-Exit-Down]],
            pushedTexCoord = { 0.140625, 0.859375, 0.140625, 0.859375 },
        }
    end
end

function VehicleBar:GetDefaults()
    return {
        point = 'CENTER',
        x = -244,
        y = 0,
        numButtons = #buttons
    }
end

function VehicleBar:AddButton(i)
    local b = buttons[i]
    if b then
        if not InCombatLockdown() then
            b:SetParent(self.header)
            b:Show()
        end
        self.buttons[i] = b
    end
end

function VehicleBar:RemoveButton(i)
    local b = self.buttons[i]
    if b then
        if not InCombatLockdown() then
            b:SetParent(nil)
            b:Hide()
        end
        self.buttons[i] = nil
    end
end

function VehicleBar:GetShowStates()
    return '[target=vehicle,exists]show;hide'
end