local _, BCS = ...
local M = { buttonSlots = {} }
BCS:RegisterModule("GearTooltips", M)

function M:Skin(tooltip)
    if tooltip.NineSlice then
        for _, region in pairs(tooltip.NineSlice) do
            if type(region) == "table" and region.SetAlpha then region:SetAlpha(0) end
        end
    end
    if not tooltip._bcsOpaqueBackground then
        local background = tooltip:CreateTexture(nil, "BACKGROUND", nil, -8)
        background:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 2, -2)
        background:SetPoint("BOTTOMRIGHT", tooltip, "BOTTOMRIGHT", -2, 2)
        tooltip._bcsOpaqueBackground = background
    end
    local bg, border = BCS.charDB.characterSheetBackgroundColor, BCS.charDB.borderColor
    tooltip._bcsOpaqueBackground:SetColorTexture(bg[1], bg[2], bg[3], 1)
    tooltip._bcsOpaqueBackground:Show()
    if tooltip.SetBackdrop then
        tooltip:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1,
            insets = { left = 3, right = 3, top = 3, bottom = 3 } })
        tooltip:SetBackdropColor(bg[1], bg[2], bg[3], 1)
        tooltip:SetBackdropBorderColor(border[1], border[2], border[3], border[4] or 1)
    end
end

function M:Process(tooltip)
    local owner = tooltip.GetOwner and tooltip:GetOwner()
    local slotID = owner and self.buttonSlots[owner]
    if not slotID or tooltip._bcsAddingSlot or tooltip._bcsSlotAdded then return end
    tooltip._bcsAddingSlot = true
    self:Skin(tooltip)
    tooltip._bcsPreviousScale = tooltip._bcsPreviousScale or tooltip:GetScale()
    tooltip:SetScale((BCS.charDB.gearTooltipScale or 100) / 100)
    tooltip:AddLine(" ")
    local r, g, b = BCS:GetAccentColor()
    tooltip:AddDoubleLine("Gear slot", tostring(slotID), r, g, b, 1, 1, 1)
    tooltip._bcsSlotAdded = true
    tooltip._bcsAddingSlot = false
end

function M:Initialize()
    BCS:WhenCharacterUIReady(function()
        for name, slotID in pairs(BCS.modules.EquipmentSlots.slots) do
            local button = _G[name]; if button then self.buttonSlots[button] = slotID end
        end
        if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum.TooltipDataType.Item then
            TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip) self:Process(tooltip) end)
        end
        GameTooltip:HookScript("OnTooltipCleared", function(tooltip)
            tooltip._bcsAddingSlot = nil; tooltip._bcsSlotAdded = nil
            if tooltip._bcsPreviousScale then tooltip:SetScale(tooltip._bcsPreviousScale); tooltip._bcsPreviousScale = nil end
        end)
        GameTooltip:HookScript("OnHide", function(tooltip)
            if tooltip._bcsPreviousScale then tooltip:SetScale(tooltip._bcsPreviousScale); tooltip._bcsPreviousScale = nil end
        end)
    end)
end
