local _, BCS = ...
local M = { mode = "stats" }
BCS:RegisterModule("SidePanels", M)

local EQUIPMENT_DIALOG_NAMES = { "GearManagerPopupFrame", "EquipmentManagerPopupFrame", "IconSelectorPopupFrame" }

local function RaiseEquipmentDialogs()
    for _, name in ipairs(EQUIPMENT_DIALOG_NAMES) do
        local popup = _G[name]
        if popup then
            popup:SetFrameStrata("TOOLTIP"); popup:SetFrameLevel(3000)
            if popup.SetToplevel then popup:SetToplevel(true) end
            if popup.IconSelector then
                popup.IconSelector:SetFrameStrata("TOOLTIP"); popup.IconSelector:SetFrameLevel(3100)
                if popup.IconSelector.SetToplevel then popup.IconSelector:SetToplevel(true) end
            end
            if popup.Raise then popup:Raise() end
        end
    end
end

local function StripContainerDecoration(container)
    if not container then return end
    for _, region in ipairs({ container:GetRegions() }) do
        if region and region.GetObjectType and region:GetObjectType() == "Texture" then region:SetAlpha(0) end
    end
    for _, key in ipairs({ "Border", "Inset", "Background", "Bg", "NineSlice", "backdrop" }) do
        local region = container[key]
        if region then
            if region.SetAlpha then region:SetAlpha(0) end
            if region.Hide then region:Hide() end
        end
    end
    if container.SetBackdrop then container:SetBackdrop(nil) end
end

local function StripTitlePane(pane)
    if not pane then return end
    StripContainerDecoration(pane)
    StripContainerDecoration(pane.ScrollBox)
    StripContainerDecoration(pane.ScrollBox and pane.ScrollBox.ScrollTarget)
end

function M:CreateContainers()
    if self.titleContainer and self.equipmentContainer then return true end
    local infoDock = BCS.modules.InfoDock
    local host = infoDock and infoDock.frame
    if not host then return false end

    self.host = host
    self.titleContainer = CreateFrame("Frame", "BoojieCharacterSheetEmbeddedTitles", host)
    self.titleContainer:SetPoint("TOPLEFT", host, "TOPLEFT", 3, -3)
    self.titleContainer:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", -3, 3)
    self.titleContainer:SetFrameLevel(host:GetFrameLevel() + 5); self.titleContainer:Hide()

    self.equipmentContainer = CreateFrame("Frame", "BoojieCharacterSheetEmbeddedEquipment", host)
    self.equipmentContainer:SetPoint("TOPLEFT", host, "TOPLEFT", 3, -3)
    self.equipmentContainer:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", -3, 3)
    self.equipmentContainer:SetFrameLevel(host:GetFrameLevel() + 5); self.equipmentContainer:Hide()
    return true
end

function M:SetMode(mode)
    mode = mode or "stats"
    if not self:CreateContainers() then return end
    self.mode = mode
    self.titleContainer:SetShown(mode == "title")
    self.equipmentContainer:SetShown(mode == "equipment")
    local infoDock = BCS.modules.InfoDock
    if infoDock and infoDock.SetContentMode then infoDock:SetContentMode(mode) end
end

function M:Attach(kind)
    if not self:CreateContainers() then return end
    local container = kind == "title" and self.titleContainer or self.equipmentContainer
    local pane = kind == "title" and PaperDollFrame.TitleManagerPane or PaperDollFrame.EquipmentManagerPane
    if not container or not pane then return end

    self:SetMode(kind)
    pane:SetParent(container); pane:ClearAllPoints()
    pane:SetPoint("TOPLEFT", container, "TOPLEFT", 1, -1)
    pane:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -1, 1)
    pane:SetFrameLevel(container:GetFrameLevel() + 1); pane:Show()

    if kind == "title" then StripTitlePane(pane) end
    if pane.ScrollBox then
        pane.ScrollBox:ClearAllPoints()
        pane.ScrollBox:SetPoint("TOPLEFT", pane, "TOPLEFT", 4, kind == "title" and -4 or -34)
        pane.ScrollBox:SetPoint("BOTTOMRIGHT", pane, "BOTTOMRIGHT", -20, 4)
    end

    if kind == "equipment" then
        RaiseEquipmentDialogs()
    end
end

function M:ShowStats()
    self:SetMode("stats")
end

function M:HideAll()
    self:ShowStats()
end

function M:TogglePanel(kind)
    local settings = BCS.modules.Settings
    if settings and settings.window then settings.window:Hide() end
    if self.mode == kind then self:ShowStats(); return end
    C_Timer.After(0, function() self:Attach(kind) end)
end

function M:InitializeEmbedded(attempt)
    if not self:CreateContainers() then
        attempt = (attempt or 0) + 1
        if attempt <= 20 then C_Timer.After(0.05, function() self:InitializeEmbedded(attempt) end) end
        return
    end

    if PaperDollSidebarTab1 then PaperDollSidebarTab1:HookScript("OnClick", function() self:ShowStats() end) end
    if PaperDollSidebarTab2 then PaperDollSidebarTab2:HookScript("OnClick", function() self:TogglePanel("title") end) end
    if PaperDollSidebarTab3 then PaperDollSidebarTab3:HookScript("OnClick", function() self:TogglePanel("equipment") end) end
    for index = 1, 5 do
        local tab = _G["CharacterFrameTab" .. index]
        if tab then tab:HookScript("OnClick", function() self:ShowStats() end) end
    end
    CharacterFrame:HookScript("OnHide", function() self:ShowStats() end)

    for _, name in ipairs(EQUIPMENT_DIALOG_NAMES) do
        local popup = _G[name]
        if popup then popup:HookScript("OnShow", function() C_Timer.After(0, RaiseEquipmentDialogs) end) end
    end
    self:ShowStats()
end

function M:Initialize()
    BCS:WhenCharacterUIReady(function()
        C_Timer.After(0, function() self:InitializeEmbedded() end)
    end)
end
