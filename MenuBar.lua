local _G = getfenv(0)
local ceil = math.ceil
local min = math.min
local max = math.max
local pairs = pairs
local ipairs = ipairs
local type = type
local InCombatLockdown = InCombatLockdown

local combatQueue = {}
local queueFrame = CreateFrame('Frame')
queueFrame:RegisterEvent('PLAYER_REGEN_ENABLED')
queueFrame:SetScript('OnEvent', function()
    for key, func in pairs(combatQueue) do
        local success, err = pcall(func)
        if not success then
            geterrorhandler()(err)
        end
        combatQueue[key] = nil
    end
end)

local function Enqueue(key, func)
    combatQueue[key] = func
end

local menuButtons = {}

do
    local function LoadDynamicButtons()
        menuButtons = {}
        
        for name, obj in pairs(_G) do
            if type(obj) == "table" and type(obj.GetObjectType) == "function" then
                if obj:GetObjectType() == "Button" or obj:GetObjectType() == "CheckButton" then
                    if name:match('(%w+)MicroButton$') and name ~= 'FriendsMicroButton' and obj:IsVisible() then
                        table.insert(menuButtons, obj)
                    end
                end
            end
        end

        table.sort(menuButtons, function(a, b)
            local aX = a:GetLeft() or 0
            local bX = b:GetLeft() or 0
            return aX < bX
        end)
    end
    
    LoadDynamicButtons()

    if TalentMicroButton then
        TalentMicroButton:SetScript('OnEvent', function(self, event)
            if (event == 'PLAYER_LEVEL_UP' or event == 'PLAYER_LOGIN') then
                if UnitCharacterPoints('player') > 0 and not CharacterFrame:IsShown() then
                    SetButtonPulse(self, 60, 1)
                end
            elseif event == 'UPDATE_BINDINGS' then
                self.tooltipText = MicroButtonTooltipText(TALENTS_BUTTON, 'TOGGLETALENTS')
            end
        end)
        TalentMicroButton:UnregisterAllEvents()
        TalentMicroButton:RegisterEvent('PLAYER_LEVEL_UP')
        TalentMicroButton:RegisterEvent('PLAYER_LOGIN')
        TalentMicroButton:RegisterEvent('UPDATE_BINDINGS')
    end

    if AchievementMicroButton then
        AchievementMicroButton:UnregisterAllEvents()
    end
end

local MenuBar = CleanBars:CreateClass('Frame', CleanBars.Frame)
CleanBars.MenuBar = MenuBar

function MenuBar:New()
    local f = self.super.New(self, 'menu')
    f:SetClampedToScreen(true)
    f:LoadButtons()
    f:Layout()
    return f
end

function MenuBar:GetDefaults()
    return {
        point = 'BOTTOMRIGHT',
        x = -244,
        y = 0,
    }
end

function MenuBar:NumButtons()
    return #menuButtons
end

function MenuBar:AddButton(i)
    if InCombatLockdown() then return end
    local b = menuButtons[i]
    if b then
        b:SetParent(self.header)
        b:Show()
        self.buttons[i] = b
    end
end

function MenuBar:RemoveButton(i)
    if InCombatLockdown() then return end
    local b = self.buttons[i]
    if b then
        b:SetParent(nil)
        b:Hide()
        self.buttons[i] = nil
    end
end

local WIDTH_OFFSET = 2 

function MenuBar:Layout()
    if InCombatLockdown() then return end

    if #self.buttons > 0 then
        local cols = min(self:NumColumns(), #self.buttons)
        local rows = ceil(#self.buttons / cols)
        local pW, pH = self:GetPadding()
        local spacing = self:GetSpacing()

        local cellWidth = 28 - WIDTH_OFFSET
        local cellHeight = 36
        local visualHeightOffset = 22

        for i, b in pairs(self.buttons) do
            local col = (i - 1) % cols
            local row = ceil(i / cols) - 1
            b:ClearAllPoints()
            
            local actualHeight = b:GetHeight() or 58
            local topPadding = max(0, actualHeight - cellHeight)
            
            local xPos = pW + (col * (cellWidth + spacing))
            local yPos = -pH - (row * (cellHeight + spacing))
            
            b:SetPoint('TOPLEFT', self.header, 'TOPLEFT', xPos, yPos + topPadding)
        end

        self:SetWidth(max((cellWidth * cols) + (spacing * (cols - 1)) + (pW * 2), 8))
        self:SetHeight(max((cellHeight * rows) + (spacing * (rows - 1)) + (pH * 2), 8))
    else
        self:SetWidth(30)
        self:SetHeight(30)
    end
end

local protectedMethods = {
    'SetNumButtons', 'SetColumns', 'SetSpacing', 'SetPadding',
    'SetScale', 'SetFrameAlpha', 'SetAlpha', 'SetShowStates',
    'SetPage', 'UpdateStateDriver', 'RefreshActions', 'UpdateGrid',
    'AddButton', 'RemoveButton', 'Layout'
}

for _, methodName in ipairs(protectedMethods) do
    local originalMethod = MenuBar[methodName]
    if originalMethod then
        MenuBar[methodName] = function(self, ...)
            if InCombatLockdown() then
                local key = methodName .. "_" .. (self.id or "global")
                local args = { ... }
                Enqueue(key, function()
                    originalMethod(self, unpack(args))
                end)
                return
            end
            return originalMethod(self, ...)
        end
    end
end