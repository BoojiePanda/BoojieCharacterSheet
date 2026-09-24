local _, BCS = ...
local M = { buttons = {} }
BCS:RegisterModule("AddonButtonDock", M)

local KNOWN_BUTTONS = {
    "PawnUI_InventoryPawnButton", "ClassCodexWidgetButton", "IcyVeinsCharacterFrameButton", "IcyVeins_CharacterFrameButton",
    "IcyVeinsButton", "IVCharacterFrameButton",
}

local function IsIntegrationButton(button)
    if not button or not button.GetObjectType or button:GetObjectType() ~= "Button" then return false end
    local name = button:GetName()
    if not name then return false end
    local lower = name:lower()
    return lower:find("pawn", 1, true) or lower:find("classcodex", 1, true)
        or lower:find("icyveins", 1, true) or lower:find("icy_veins", 1, true)
end

function M:CreateDock()
    local frame = CreateFrame("Frame", "BoojieCharacterSheetAddonButtonDock", PaperDollFrame, "BackdropTemplate")
    frame:SetPoint("BOTTOMRIGHT", CharacterFrame, "BOTTOMRIGHT", -8, 10); frame:SetHeight(28)
    frame:SetBackdrop(nil)
    self.frame = frame
end

function M:FindButtons()
    local found, seen = {}, {}
    local function Add(button, registered)
        if button and (registered or IsIntegrationButton(button)) and not seen[button] then seen[button] = true; found[#found + 1] = button end
    end
    for _, name in ipairs(KNOWN_BUTTONS) do Add(_G[name]) end
    for _, owner in ipairs({ PaperDollFrame, CharacterFrame }) do
        if owner then for _, child in ipairs({ owner:GetChildren() }) do Add(child) end end
    end
    local registry = BCS.modules.DockRegistry
    if registry then
        for _, entry in ipairs(registry:Ordered()) do
            local provider = entry.provider
            Add(provider.button or (provider.GetButton and provider:GetButton()), true)
        end
    end
    table.sort(found, function(a, b) return (a:GetName() or "") < (b:GetName() or "") end)
    self.buttons = found
end

function M:Layout()
    if not self.frame then return end
    self:FindButtons()
    local previous
    for _, button in ipairs(self.buttons) do
        local mover = button:GetName() == "ClassCodexWidgetButton" and button:GetParent() or button
        mover:ClearAllPoints()
        if previous then mover:SetPoint("RIGHT", previous, "LEFT", -5, 0) else mover:SetPoint("RIGHT", self.frame, "RIGHT", 0, 0) end
        button:SetFrameLevel(self.frame:GetFrameLevel() + 2); button:Show(); previous = button
        if mover ~= button then mover:Show() end
        if button.SetBackdrop then button:SetBackdrop(nil) end
        if button:GetName() == "PawnUI_InventoryPawnButton" and not button._bcsBorderless then
            local normal = button:GetNormalTexture()
            if normal then normal:SetTexCoord(0.035, 0.465, 0.06, 0.44) end
            local pushed = button:GetPushedTexture()
            if pushed then pushed:SetTexCoord(0.035, 0.465, 0.56, 0.94) end
            local disabled = button:GetDisabledTexture()
            if disabled then disabled:SetTexCoord(0.535, 0.965, 0.56, 0.94) end
            local highlight = button:GetHighlightTexture()
            if highlight then highlight:SetTexCoord(0.535, 0.965, 0.06, 0.44) end
            button._bcsBorderless = true
        end
    end
    local width = 8
    for _, button in ipairs(self.buttons) do width = width + math.max(24, button:GetWidth()) + 4 end
    self.frame:SetWidth(math.max(56, width)); self.frame:SetShown(#self.buttons > 0 and PaperDollFrame:IsShown())
end

function M:Refresh()
    if not self.frame then return end
    self:Layout()
end

function M:Initialize()
    BCS:WhenCharacterUIReady(function()
        self:CreateDock()
        CharacterFrame:HookScript("OnShow", function() C_Timer.After(0, function() self:Refresh() end) end)
        PaperDollFrame:HookScript("OnShow", function() C_Timer.After(0, function() self:Refresh() end) end)
        PaperDollFrame:HookScript("OnHide", function() self.frame:Hide() end)
        local loader = CreateFrame("Frame"); loader:RegisterEvent("ADDON_LOADED")
        loader:SetScript("OnEvent", function(_, _, addon)
            if addon == "Pawn" or addon == "IcyVeins" or addon == "IcyVeins_CharacterFrame" then
                C_Timer.After(0, function() self:Refresh() end)
            end
        end)
        if type(PawnUI_InventoryPawnButton_Move) == "function" then
            hooksecurefunc("PawnUI_InventoryPawnButton_Move", function() C_Timer.After(0, function() self:Layout() end) end)
        end
        self.loader = loader; self:Refresh()
    end)
end
