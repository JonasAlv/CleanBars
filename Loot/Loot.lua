local MODULE = CleanBars:NewModule('loot')
local C = ConfigLocale 
local LootFrameClass

function MODULE:Load()
    if not self.frame then
        self.frame = LootFrameClass:New()
    end
end

function MODULE:Unload()
    if self.frame then
        self.frame:Free()
        self.frame = nil
    end
end

LootFrameClass = CleanBars:CreateClass('Frame', CleanBars.Frame)

function LootFrameClass:New()
    local f = self.super.New(self, 'loot', C.TipLootFrame)
    f:LoadButtons()
    f:Layout()
    return f
end

function LootFrameClass:GetDefaults()
    return {
        point = 'LEFT',
        numButtons = NUM_GROUP_LOOT_FRAMES,
        columns = 1,
        spacing = 2
    }
end

function LootFrameClass:AddButton(i)
    local b = _G['GroupLootFrame' .. (5 - i)]
    if b then
        b:SetParent(self.header)
        self.buttons[i] = b
    end
end

function LootFrameClass:RemoveButton(i)
    local b = self.buttons[i]
    if b then
        b:SetParent(nil)
        self.buttons[i] = nil
    end
end

UIPARENT_MANAGED_FRAME_POSITIONS['GroupLootFrame1'] = nil

do
    local parentMenuName = CleanBars.Options.name
    local lootPanel = CleanBars.Options:New('CleanBarsLootOptions', C.LootBarTitle, C.LootBarDesc, parentMenuName)
    local enableLootCB = lootPanel:NewCheckButton('EnableLootMod', C.EnableLootMod)
    enableLootCB:SetPoint('TOPLEFT', 16, -80)
    
    enableLootCB:SetScript('OnShow', function(self)
        self:SetChecked(CleanBars.db.global.modules.loot ~= false)
    end)
    
    enableLootCB:SetScript('OnClick', function(self)
        local checked = self:GetChecked() and true or false
        CleanBars.db.global.modules.loot = checked
        
        if checked then
            MODULE:Load()
            if MODULE.frame and MODULE.frame.Reanchor then MODULE.frame:Reanchor() end
        else
            MODULE:Unload()
        end
    end)
end