CleanBars = LibStub('AceAddon-3.0'):NewAddon('CleanBars', 'AceEvent-3.0', 'AceConsole-3.0')
local L = Locale
local CURRENT_VERSION = GetAddOnMetadata('CleanBars', 'Version')

local UIHider = CreateFrame('Frame', 'CleanBarsUIHider')
UIHider:Hide()

function CleanBars:OnInitialize()
    self.db = LibStub('AceDB-3.0'):New('CleanBarsDB', self:GetDefaults(), select(2, UnitClass('player')))
    self.db.RegisterCallback(self, 'OnNewProfile')
    self.db.RegisterCallback(self, 'OnProfileChanged')
    self.db.RegisterCallback(self, 'OnProfileCopied')
    self.db.RegisterCallback(self, 'OnProfileReset')
    self.db.RegisterCallback(self, 'OnProfileDeleted')

    if CleanBarsVersion then
        if CleanBarsVersion ~= CURRENT_VERSION then
            self:UpdateSettings(CleanBarsVersion:match('(%w+)%.(%w+)%.(%w+)'))
            self:UpdateVersion()
        end
    else
        CleanBarsVersion = CURRENT_VERSION
    end

    self:RegisterSlashCommands()
    
    local kb = LibStub('LibKeyBound-1.0')
    kb.RegisterCallback(self, 'LIBKEYBOUND_ENABLED')
    kb.RegisterCallback(self, 'LIBKEYBOUND_DISABLED')

    local ButtonFacade = LibStub('LibButtonFacade', true)
    if ButtonFacade then
        ButtonFacade:RegisterSkinCallback('CleanBars', self.OnSkin, self)
    end
end

function CleanBars:OnEnable()
    self:HideBlizzard()
    self:Load()

    if LibStub:GetLibrary('LibDataBroker-1.1', true) then
        self:LoadDataBrokerPlugin()
    end

    local combatBlocker = CreateFrame('Frame')
    combatBlocker:RegisterEvent('PLAYER_REGEN_DISABLED')
    combatBlocker:SetScript('OnEvent', function()
        if not self:Locked() then
            self:SetLock(true)
            self:Print("Config mode auto-closed due to combat lockdown.")
        end
        
        local kb = LibStub('LibKeyBound-1.0', true)
        if kb and kb:IsShown() then
            kb:Deactivate()
            self:Print("Binding mode auto-closed due to combat lockdown.")
        end
    end)
end

function CleanBars:LoadDataBrokerPlugin()
    LibStub:GetLibrary('LibDataBroker-1.1'):NewDataObject('CleanBars', {
        type = 'launcher',

        OnClick = function(_, button)
            if button == 'LeftButton' then
                if IsShiftKeyDown() then
                    CleanBars:ToggleBindingMode()
                else
                    CleanBars:ToggleLockedFrames()
                end
            elseif button == 'RightButton' then
                CleanBars:ShowOptions()
            end
        end,

        OnTooltipShow = function(tooltip)
            if not tooltip or not tooltip.AddLine then return end
            tooltip:AddLine('CleanBars')

            if CleanBars:Locked() then
                tooltip:AddLine(L.ConfigEnterTip)
            else
                tooltip:AddLine(L.ConfigExitTip)
            end

            local KB = LibStub('LibKeyBound-1.0', true)
            if KB then
                if KB:IsShown() then
                    tooltip:AddLine(L.BindingExitTip)
                else
                    tooltip:AddLine(L.BindingEnterTip)
                end
            end

            if CleanBars.Menu then
                tooltip:AddLine(L.ShowOptionsTip)
            end
        end,
    })
end

function CleanBars:GetDefaults()
    return {
        global = {
            modules = {}, 
        },
        profile = {
            possessBar = 1,
            sticky = true,
            linkedOpacity = false,
            showMacroText = true,
            showBindingText = true,
            showTooltips = true,
            showMinimap = true,
            ab = {
                count = 10,
                showgrid = true,
                style = {'Entropy: Copper', 0.5, true},
            },
            petStyle = {'Entropy: Copper', 0.5, true},
            classStyle = {'Entropy: Copper', 0.5, true},
            bagStyle = {'Entropy: Copper', 0.5, true},
            frames = {}
        }
    }
end

function CleanBars:UpdateSettings(major, minor, bugfix)
    if major == '1' and minor <= '12' then
        for profile,sets in pairs(self.db.sv.profiles) do
            local frames = sets.frames
            if frames then
                for frameID, frameSets in pairs(frames) do
                    frameSets.isLeftToRight = nil
                    frameSets.isRightToLeft = nil
                    frameSets.isTopToBottom = nil
                    frameSets.isBottomToTop = nil
                end
            end
        end
    end
    
    if major == '1' and minor <= '14' then
        for profile,sets in pairs(self.db.sv.profiles) do
            local frames = sets.frames
            if frames then
                for frameID, frameSets in pairs(frames) do
                    if tostring(frameID):match('^totem(%d+)') then
                        frameSets.showRecall = true
                        frameSets.showTotems = true
                    end
                end
            end
        end
    end
end

function CleanBars:UpdateVersion()
    CleanBarsVersion = CURRENT_VERSION
    self:Print(format(L.Updated, CleanBarsVersion))
end

function CleanBars:Load()
    for i = 1, self:NumBars() do
        self.ActionBar:New(i)
    end
    
    self.ClassBar:New()
    self.PetBar:New()
    self.BagBar:New()
    self.MenuBar:New()
    self.VehicleBar:New()

    if self.TotemBar and self.TotemBar.Initialize then
        self.TotemBar:Initialize()
    end

    local bf = LibStub('LibButtonFacade', true)
    if bf then
        bf:Group('CleanBars', 'Action Bar'):Skin(unpack(self.db.profile.ab.style))
        bf:Group('CleanBars', 'Pet Bar'):Skin(unpack(self.db.profile.petStyle))
        bf:Group('CleanBars', 'Class Bar'):Skin(unpack(self.db.profile.classStyle))
        bf:Group('CleanBars', 'Bag Bar'):Skin(unpack(self.db.profile.bagStyle))
    end

    for name, module in self:IterateModules() do
        if self.db.global.modules[name] ~= false then
            module:Load()
        else
            module:Unload()
        end
    end
    
    self.Frame:ForAll('Reanchor')
    self:UpdateMinimapButton()
end

function CleanBars:Unload()
    self.ActionBar:ForAll('Free')
    self.Frame:ForFrame('pet', 'Free')
    self.Frame:ForFrame('class', 'Free')
    self.Frame:ForFrame('menu', 'Free')
    self.Frame:ForFrame('bags', 'Free')
    self.Frame:ForFrame('vehicle', 'Free')

    if self.TotemBar and self.TotemBar.UnloadBars then
        self.TotemBar:UnloadBars()
    end

    for _, module in self:IterateModules() do
        module:Unload()
    end
end

function CleanBars:HideBlizzard()
    if not _G['VehicleSeatIndicator']:IsUserPlaced() then
        _G['VehicleSeatIndicator']:SetPoint("TOPRIGHT", MinimapCluster, "BOTTOMRIGHT", 0, -13)
    end

    UIPARENT_MANAGED_FRAME_POSITIONS['MultiBarRight'] = nil
    UIPARENT_MANAGED_FRAME_POSITIONS['MultiBarLeft'] = nil
    UIPARENT_MANAGED_FRAME_POSITIONS['MultiBarBottomLeft'] = nil
    UIPARENT_MANAGED_FRAME_POSITIONS['MultiBarBottomRight'] = nil
    UIPARENT_MANAGED_FRAME_POSITIONS['MainMenuBar'] = nil
    UIPARENT_MANAGED_FRAME_POSITIONS['ShapeshiftBarFrame'] = nil
    UIPARENT_MANAGED_FRAME_POSITIONS['PossessBarFrame'] = nil
    UIPARENT_MANAGED_FRAME_POSITIONS['PETACTIONBAR_YPOS'] = nil

    MainMenuBar:UnregisterAllEvents()
    MainMenuBarArtFrame:UnregisterAllEvents()
    MainMenuExpBar:UnregisterAllEvents()
    ShapeshiftBarFrame:UnregisterAllEvents()
    BonusActionBarFrame:UnregisterAllEvents()
    PossessBarFrame:UnregisterAllEvents()

    MainMenuBar:SetParent(UIHider)
    MainMenuBarArtFrame:SetParent(UIHider)
    MainMenuExpBar:SetParent(UIHider)
    ShapeshiftBarFrame:SetParent(UIHider)
    BonusActionBarFrame:SetParent(UIHider)
    PossessBarFrame:SetParent(UIHider)
    
    hooksecurefunc('TalentFrame_LoadUI', function()
        PlayerTalentFrame:UnregisterEvent('ACTIVE_TALENT_GROUP_CHANGED')
    end)
end

function CleanBars:OnSkin(skin, glossAlpha, gloss, group, _, colors)
    local styleDB
    if group == 'Action Bar' then
        styleDB = self.db.profile.ab.style
    elseif group == 'Pet Bar' then
        styleDB = self.db.profile.petStyle
    elseif group == 'Class Bar' then
        styleDB = self.db.profile.classStyle
    elseif group == 'Bag Bar' then
        styleDB = self.db.profile.bagStyle
    end

    if styleDB then
        styleDB[1] = skin
        styleDB[2] = glossAlpha
        styleDB[3] = gloss
        styleDB[4] = colors
    end
end

function CleanBars:LIBKEYBOUND_ENABLED()
    for _,frame in self.Frame:GetAll() do
        if frame.KEYBOUND_ENABLED then frame:KEYBOUND_ENABLED() end
    end
end

function CleanBars:LIBKEYBOUND_DISABLED()
    for _,frame in self.Frame:GetAll() do
        if frame.KEYBOUND_DISABLED then frame:KEYBOUND_DISABLED() end
    end
end

StaticPopupDialogs['CLEANBARS_RELOAD_UI'] = {
    text = "A UI reload is required to fully apply profile changes. Reload now?",
    button1 = ACCEPT,
    button2 = CANCEL,
    OnAccept = function()
        ReloadUI()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

function CleanBars:SaveProfile(name)
    local toCopy = self.db:GetCurrentProfile()
    if name and name ~= toCopy then
        self:Unload()
        self.db:SetProfile(name)
        self.db:CopyProfile(toCopy)
        self.isNewProfile = nil
        self:Load()
        StaticPopup_Show('CLEANBARS_RELOAD_UI')
    end
end

function CleanBars:SetProfile(name)
    local profile = self:MatchProfile(name)
    if profile and profile ~= self.db:GetCurrentProfile() then
        self:Unload()
        self.db:SetProfile(profile)
        self.isNewProfile = nil
        self:Load()
        StaticPopup_Show('CLEANBARS_RELOAD_UI')
    else
        self:Print(format(L.InvalidProfile, name or 'null'))
    end
end

function CleanBars:DeleteProfile(name)
    local profile = self:MatchProfile(name)
    if profile and profile ~= self.db:GetCurrentProfile() then
        self.db:DeleteProfile(profile)
    else
        self:Print(L.CantDeleteCurrentProfile)
    end
end

function CleanBars:CopyProfile(name)
    if name and name ~= self.db:GetCurrentProfile() then
        self:Unload()
        self.db:CopyProfile(name)
        self.isNewProfile = nil
        self:Load()
        StaticPopup_Show('CLEANBARS_RELOAD_UI')
    end
end

function CleanBars:ResetProfile()
    self:Unload()
    self.db:ResetProfile()
    self.isNewProfile = true
    self:Load()
    StaticPopup_Show('CLEANBARS_RELOAD_UI')
end

function CleanBars:ListProfiles()
    self:Print(L.AvailableProfiles)
    local current = self.db:GetCurrentProfile()
    for _,k in ipairs(self.db:GetProfiles()) do
        if k == current then
            DEFAULT_CHAT_FRAME:AddMessage(' - ' .. k, 1, 1, 0)
        else
            DEFAULT_CHAT_FRAME:AddMessage(' - ' .. k)
        end
    end
end

function CleanBars:MatchProfile(name)
    local name = name:lower()
    local nameRealm = name .. ' - ' .. GetRealmName():lower()
    local match

    for i, k in ipairs(self.db:GetProfiles()) do
        local key = k:lower()
        if key == name then
            return k
        elseif key == nameRealm then
            match = k
        end
    end
    return match
end

function CleanBars:OnNewProfile(msg, db, name)
    self.isNewProfile = true
    self:Print(format(L.ProfileCreated, name))
end

function CleanBars:OnProfileDeleted(msg, db, name)
    self:Print(format(L.ProfileDeleted, name))
end

function CleanBars:OnProfileChanged(msg, db, name)
    self:Print(format(L.ProfileLoaded, name))
end

function CleanBars:OnProfileCopied(msg, db, name)
    self:Print(format(L.ProfileCopied, name))
end

function CleanBars:OnProfileReset(msg, db)
    self:Print(format(L.ProfileReset, db:GetCurrentProfile()))
end

function CleanBars:SetFrameSets(id, sets)
    local id = tonumber(id) or id
    self.db.profile.frames[id] = sets
    return self.db.profile.frames[id]
end

function CleanBars:GetFrameSets(id)
    return self.db.profile.frames[tonumber(id) or id]
end

function CleanBars:ShowOptions()
    if InCombatLockdown() then
        self:Print("Can't change settings in combat.")
        return true
    end
    InterfaceOptionsFrame_OpenToCategory(self.Options)
    return true
end

function CleanBars:NewMenu(id)
    return self.Menu and self.Menu:New(id)
end

function CleanBars:RegisterSlashCommands()
    self:RegisterChatCommand('cleanbars', 'OnCmd')
    self:RegisterChatCommand('cb', 'OnCmd')
end

function CleanBars:OnCmd(args)
    if InCombatLockdown() then
        self:Print("Can't change settings in combat.")
        return
    end

    local cmd = string.split(' ', args):lower() or args:lower()
    
    if cmd == 'config' or cmd == 'lock' then
        self:ToggleLockedFrames()
    elseif cmd == 'scale' then
        self:ScaleFrames(select(2, string.split(' ', args)))
    elseif cmd == 'setalpha' then
        self:SetOpacityForFrames(select(2, string.split(' ', args)))
    elseif cmd == 'fade' then
        self:SetFadeForFrames(select(2, string.split(' ', args)))
    elseif cmd == 'setcols' then
        self:SetColumnsForFrames(select(2, string.split(' ', args)))
    elseif cmd == 'pad' then
        self:SetPaddingForFrames(select(2, string.split(' ', args)))
    elseif cmd == 'space' then
        self:SetSpacingForFrame(select(2, string.split(' ', args)))
    elseif cmd == 'show' then
        self:ShowFrames(select(2, string.split(' ', args)))
    elseif cmd == 'hide' then
        self:HideFrames(select(2, string.split(' ', args)))
    elseif cmd == 'toggle' then
        self:ToggleFrames(select(2, string.split(' ', args)))
    elseif cmd == 'numbars' then
        self:SetNumBars(tonumber(select(2, string.split(' ', args))))
    elseif cmd == 'numbuttons' then
        self:SetNumButtons(tonumber(select(2, string.split(' ', args))))
    elseif cmd == 'save' then
        local profileName = string.join(' ', select(2, string.split(' ', args)))
        self:SaveProfile(profileName)
    elseif cmd == 'set' then
        local profileName = string.join(' ', select(2, string.split(' ', args)))
        self:SetProfile(profileName)
    elseif cmd == 'copy' then
        local profileName = string.join(' ', select(2, string.split(' ', args)))
        self:CopyProfile(profileName)
    elseif cmd == 'delete' then
        local profileName = string.join(' ', select(2, string.split(' ', args)))
        self:DeleteProfile(profileName)
    elseif cmd == 'reset' then
        self:ResetProfile()
    elseif cmd == 'list' then
        self:ListProfiles()
    elseif cmd == 'version' then
        self:PrintVersion()
    elseif cmd == 'help' or cmd == '?' then
        self:PrintHelp()
    else
        if not self:ShowOptions() then self:PrintHelp() end
    end
end

function CleanBars:PrintHelp(cmd)
    local function PrintCmd(cmd, desc)
        print(format(' - |cFF33FF99%s|r: %s', cmd, desc))
    end
    self:Print('Commands (/cb, /cleanbars)')
    PrintCmd('config', L.ConfigDesc)
    PrintCmd('scale <frameList> <scale>', L.SetScaleDesc)
    PrintCmd('setalpha <frameList> <opacity>', L.SetAlphaDesc)
    PrintCmd('fade <frameList> <opacity>', L.SetFadeDesc)
    PrintCmd('setcols <frameList> <columns>', L.SetColsDesc)
    PrintCmd('pad <frameList> <padding>', L.SetPadDesc)
    PrintCmd('space <frameList> <spacing>', L.SetSpacingDesc)
    PrintCmd('show <frameList>', L.ShowFramesDesc)
    PrintCmd('hide <frameList>', L.HideFramesDesc)
    PrintCmd('toggle <frameList>', L.ToggleFramesDesc)
    PrintCmd('save <profile>', L.SaveDesc)
    PrintCmd('set <profile>', L.SetDesc)
    PrintCmd('copy <profile>', L.CopyDesc)
    PrintCmd('delete <profile>', L.DeleteDesc)
    PrintCmd('reset', L.ResetDesc)
    PrintCmd('list', L.ListDesc)
    PrintCmd('version', L.PrintVersionDesc)
end

function CleanBars:PrintVersion()
    self:Print(CleanBarsVersion)
end

CleanBars.locked = true

local function CreateConfigHelperDialog()
    local f = CreateFrame('Frame', 'CleanBarsConfigHelperDialog', UIParent)
    f:SetFrameStrata('DIALOG')
    f:SetToplevel(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:SetWidth(360)
    f:SetHeight(120)
    f:SetBackdrop{
        bgFile='Interface\\DialogFrame\\UI-DialogBox-Background' ,
        edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',
        tile = true,
        insets = {left = 11, right = 12, top = 12, bottom = 11},
        tileSize = 32,
        edgeSize = 32,
    }
    f:SetPoint('TOP', 0, -24)
    f:Hide()
    f:SetScript('OnShow', function() PlaySound('igMainMenuOption') end)
    f:SetScript('OnHide', function() PlaySound('gsTitleOptionExit') end)

    local tr = f:CreateTitleRegion()
    tr:SetAllPoints(f)

    local header = f:CreateTexture(nil, 'ARTWORK')
    header:SetTexture('Interface\\DialogFrame\\UI-DialogBox-Header')
    header:SetWidth(326); header:SetHeight(64)
    header:SetPoint('TOP', 0, 12)

    local title = f:CreateFontString('ARTWORK')
    title:SetFontObject('GameFontNormal')
    title:SetPoint('TOP', header, 'TOP', 0, -14)
    title:SetText(L.ConfigMode)

    local desc = f:CreateFontString('ARTWORK')
    desc:SetFontObject('GameFontHighlight')
    desc:SetJustifyV('TOP')
    desc:SetJustifyH('LEFT')
    desc:SetPoint('TOPLEFT', 18, -32)
    desc:SetPoint('BOTTOMRIGHT', -18, 48)
    desc:SetText(L.ConfigModeHelp)

    local exitConfig = CreateFrame('CheckButton', f:GetName() .. 'ExitConfig', f, 'OptionsButtonTemplate')
    _G[exitConfig:GetName() .. 'Text']:SetText(EXIT)
    exitConfig:SetScript('OnClick', function() CleanBars:SetLock(true) end)
    exitConfig:SetPoint('BOTTOMRIGHT', -14, 14)

    return f
end

function CleanBars:ShowConfigHelper()
    if not self.configHelper then self.configHelper = CreateConfigHelperDialog() end
    self.configHelper:Show()
end

function CleanBars:HideConfigHelper()
    if self.configHelper then self.configHelper:Hide() end
end

function CleanBars:SetLock(enable)
    if InCombatLockdown() and not enable then
        self:Print("Can't change settings in combat.")
        return
    end

    self.locked = enable or false
    if self:Locked() then
        self.Frame:ForAll('Lock')
        self:HideConfigHelper()
    else
        self.Frame:ForAll('Unlock')
        LibStub('LibKeyBound-1.0'):Deactivate()
        self:ShowConfigHelper()
    end
end

function CleanBars:Locked() return self.locked end

function CleanBars:ToggleLockedFrames() 
    if InCombatLockdown() then
        self:Print("Can't change settings in combat.")
        return
    end
    self:SetLock(not self:Locked()) 
end

function CleanBars:ToggleBindingMode() 
    if InCombatLockdown() then
        self:Print("Can't change settings in combat.")
        return
    end
    self:SetLock(true) 
    LibStub('LibKeyBound-1.0'):Toggle() 
end

function CleanBars:ScaleFrames(...)
    local numArgs = select('#', ...)
    local scale = tonumber(select(numArgs, ...))
    if scale and scale > 0 and scale <= 10 then
        for i = 1, numArgs - 1 do self.Frame:ForFrame(select(i, ...), 'SetFrameScale', scale) end
    end
end

function CleanBars:SetOpacityForFrames(...)
    local numArgs = select('#', ...)
    local alpha = tonumber(select(numArgs, ...))
    if alpha and alpha >= 0 and alpha <= 1 then
        for i = 1, numArgs - 1 do self.Frame:ForFrame(select(i, ...), 'SetFrameAlpha', alpha) end
    end
end

function CleanBars:SetFadeForFrames(...)
    local numArgs = select('#', ...)
    local alpha = tonumber(select(numArgs, ...))
    if alpha and alpha >= 0 and alpha <= 1 then
        for i = 1, numArgs - 1 do self.Frame:ForFrame(select(i, ...), 'SetFadeMultiplier', alpha) end
    end
end

function CleanBars:SetColumnsForFrames(...)
    local numArgs = select('#', ...)
    local cols = tonumber(select(numArgs, ...))
    if cols then
        for i = 1, numArgs - 1 do self.Frame:ForFrame(select(i, ...), 'SetColumns', cols) end
    end
end

function CleanBars:SetSpacingForFrame(...)
    local numArgs = select('#', ...)
    local spacing = tonumber(select(numArgs, ...))
    if spacing then
        for i = 1, numArgs - 1 do self.Frame:ForFrame(select(i, ...), 'SetSpacing', spacing) end
    end
end

function CleanBars:SetPaddingForFrames(...)
    local numArgs = select('#', ...)
    local pW, pH = select(numArgs - 1, ...)
    if tonumber(pW) and tonumber(pH) then
        for i = 1, numArgs - 2 do self.Frame:ForFrame(select(i, ...), 'SetPadding', tonumber(pW), tonumber(pH)) end
    end
end

function CleanBars:ShowFrames(...)
    for i = 1, select('#', ...) do self.Frame:ForFrame(select(i, ...), 'ShowFrame') end
end

function CleanBars:HideFrames(...)
    for i = 1, select('#', ...) do self.Frame:ForFrame(select(i, ...), 'HideFrame') end
end

function CleanBars:ToggleFrames(...)
    for i = 1, select('#', ...) do self.Frame:ForFrame(select(i, ...), 'ToggleFrame') end
end

function CleanBars:ToggleGrid() self:SetShowGrid(not self:ShowGrid()) end
function CleanBars:SetShowGrid(enable)
    self.db.profile.showgrid = enable or false
    self.ActionBar:ForAll('UpdateGrid')
end
function CleanBars:ShowGrid() return self.db.profile.showgrid end

function CleanBars:SetRightClickUnit(unit)
    self.db.profile.ab.rightClickUnit = unit
    self.ActionBar:ForAll('UpdateRightClickUnit')
end
function CleanBars:GetRightClickUnit() return self.db.profile.ab.rightClickUnit end

function CleanBars:SetShowBindingText(enable)
    self.db.profile.showBindingText = enable or false
    for _,f in self.Frame:GetAll() do
        if f.buttons then
            for _,b in pairs(f.buttons) do
                if b.UpdateHotkey then b:UpdateHotkey() end
            end
        end
    end
end
function CleanBars:ShowBindingText() return self.db.profile.showBindingText end

function CleanBars:SetShowMacroText(enable)
    self.db.profile.showMacroText = enable or false
    for _,f in self.Frame:GetAll() do
        if f.buttons then
            for _,b in pairs(f.buttons) do
                if b.UpdateMacro then b:UpdateMacro() end
            end
        end
    end
end
function CleanBars:ShowMacroText() return self.db.profile.showMacroText end

function CleanBars:SetPossessBar(id)
    local prevBar = self:GetPossessBar()
    self.db.profile.possessBar = id
    local newBar = self:GetPossessBar()
    prevBar:UpdateStateDriver()
    newBar:UpdateStateDriver()
end
function CleanBars:GetPossessBar() return self.Frame:Get(self.db.profile.possessBar) end
function CleanBars:GetVehicleBar() return self:GetPossessBar() end

function CleanBars:SetNumBars(count)
    count = max(min(count, 120), 1) 
    if count ~= self:NumBars() then
        self.ActionBar:ForAll('Delete')
        self.db.profile.ab.count = count
        for i = 1, self:NumBars() do self.ActionBar:New(i) end
    end
end
function CleanBars:SetNumButtons(count) self:SetNumBars(120 / count) end
function CleanBars:NumBars() return self.db.profile.ab.count end
function CleanBars:ShowTooltips() return self.db.profile.showTooltips end
function CleanBars:SetShowTooltips(enable) self.db.profile.showTooltips = enable or false end

function CleanBars:SetShowMinimap(enable)
    self.db.profile.showMinimap = enable or false
    self:UpdateMinimapButton()
end
function CleanBars:ShowingMinimap() return self.db.profile.showMinimap end

function CleanBars:UpdateMinimapButton()
    if self:ShowingMinimap() then
        self.Minimap:UpdatePosition()
        self.Minimap:Show()
    else
        self.Minimap:Hide()
    end
end

function CleanBars:SetMinimapButtonPosition(angle) self.db.profile.minimapPos = angle end
function CleanBars:GetMinimapButtonPosition(angle) return self.db.profile.minimapPos end

function CleanBars:SetSticky(enable)
    self.db.profile.sticky = enable or false
    if not enable then
        self.Frame:ForAll('Stick')
        self.Frame:ForAll('Reposition')
    end
end
function CleanBars:Sticky() return self.db.profile.sticky end
function CleanBars:SetLinkedOpacity(enable) self.db.profile.linkedOpacity = enable or false end
function CleanBars:IsLinkedOpacityEnabled() return self.db.profile.linkedOpacity end

function CleanBars:CreateClass(type, parentClass)
    local class = CreateFrame(type)
    class.mt = {__index = class}
    if parentClass then
        class = setmetatable(class, {__index = parentClass})
        class.super = parentClass
    end
    function class:Bind(o) return setmetatable(o, self.mt) end
    return class
end