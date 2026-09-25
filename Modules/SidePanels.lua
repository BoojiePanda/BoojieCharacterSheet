local _, BCS = ...
local M = { mode = "stats" }
BCS:RegisterModule("SidePanels", M)

local EQUIPMENT_DIALOG_NAMES = { "GearManagerPopupFrame", "EquipmentManagerPopupFrame", "IconSelectorPopupFrame" }
local StripContainerDecoration

local function SkinEquipmentButton(button)
    if not button then return end
    if not button._bcsSkin then
        StripContainerDecoration(button)
        local background = CreateFrame("Frame", nil, button, "BackdropTemplate")
        background:SetAllPoints()
        background:SetFrameLevel(math.max(0, button:GetFrameLevel() - 1))
        background:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        button._bcsSkin = background
        button:HookScript("OnEnter", function(current)
            local accent = BCS.charDB.accentColor
            current._bcsSkin:SetBackdropBorderColor(accent[1], accent[2], accent[3], accent[4] or 1)
        end)
        button:HookScript("OnLeave", function(current)
            local border = BCS.charDB.borderColor
            current._bcsSkin:SetBackdropBorderColor(border[1], border[2], border[3], border[4] or 1)
        end)
        button:HookScript("OnEnable", SkinEquipmentButton)
        button:HookScript("OnDisable", SkinEquipmentButton)
    end
    local background, border = BCS.charDB.attributesBackgroundColor, BCS.charDB.borderColor
    button._bcsSkin:SetBackdropColor(background[1], background[2], background[3], background[4] or 1)
    button._bcsSkin:SetBackdropBorderColor(border[1], border[2], border[3], border[4] or 1)
    local fontString = button.GetFontString and button:GetFontString()
    if fontString then
        BCS.modules.Fonts:Apply(fontString, "miscTextSize")
        local text = BCS.charDB.textColor
        fontString:SetTextColor(text[1], text[2], text[3], button:IsEnabled() and (text[4] or 1) or 0.45)
    end
end

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

StripContainerDecoration = function(container)
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

local function StripTitleRow(row)
    if not row then return end
    for _, key in ipairs({ "BgTop", "BgMiddle", "BgBottom" }) do
        local texture = row[key]
        if texture then texture:SetAlpha(0) end
    end
end

local function StripTitlePane(pane)
    if not pane then return end
    StripContainerDecoration(pane)
    StripContainerDecoration(pane.ScrollBox)
    StripContainerDecoration(pane.ScrollBox and pane.ScrollBox.ScrollTarget)
    if pane.ScrollBox and pane.ScrollBox.ForEachFrame then
        pane.ScrollBox:ForEachFrame(StripTitleRow)
    end
end

local function KeepTitlePaneClear(pane)
    if not pane or pane._bcsClearHooks then return end
    pane._bcsClearHooks = true
    pane:HookScript("OnShow", function(current) StripTitlePane(current) end)
    local scrollBox = pane.ScrollBox
    if scrollBox then
        scrollBox:HookScript("OnShow", function() StripTitlePane(pane) end)
        if scrollBox.Update then
            hooksecurefunc(scrollBox, "Update", function() StripTitlePane(pane) end)
        end
    end
end

local function RemoveEquipmentRowHover(row)
    if not row then return end
    if not row._bcsHoverRemoved then
        row._bcsHoverRemoved = true
        row:HookScript("OnEnter", RemoveEquipmentRowHover)
        row:HookScript("OnLeave", RemoveEquipmentRowHover)
    end
    if row.HighlightBar then
        row.HighlightBar:SetAlpha(0)
        row.HighlightBar:Hide()
    end
    local highlight = row.GetHighlightTexture and row:GetHighlightTexture()
    if highlight then highlight:SetAlpha(0) end
end

local function RefreshEquipmentRows(pane)
    local scrollBox = pane and pane.ScrollBox
    if scrollBox and scrollBox.ForEachFrame then
        scrollBox:ForEachFrame(RemoveEquipmentRowHover)
    end
end

local function KeepEquipmentRowsStyled(pane)
    if not pane or pane._bcsRowHooks then return end
    pane._bcsRowHooks = true
    pane:HookScript("OnShow", function(current) RefreshEquipmentRows(current) end)
    local scrollBox = pane.ScrollBox
    if scrollBox then
        scrollBox:HookScript("OnShow", function() RefreshEquipmentRows(pane) end)
        if scrollBox.Update then
            hooksecurefunc(scrollBox, "Update", function() RefreshEquipmentRows(pane) end)
        end
    end
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

    if kind == "title" then
        KeepTitlePaneClear(pane)
        StripTitlePane(pane)
    end
    if pane.ScrollBox then
        pane.ScrollBox:ClearAllPoints()
        pane.ScrollBox:SetPoint("TOPLEFT", pane, "TOPLEFT", 4, kind == "title" and -4 or -34)
        pane.ScrollBox:SetPoint("BOTTOMRIGHT", pane, "BOTTOMRIGHT", -20, 4)
    end

    if kind == "title" then C_Timer.After(0, function() StripTitlePane(pane) end) end

    if kind == "equipment" then
        KeepEquipmentRowsStyled(pane)
        RefreshEquipmentRows(pane)
        SkinEquipmentButton(PaperDollFrameEquipSet)
        SkinEquipmentButton(PaperDollFrameSaveSet)
        RaiseEquipmentDialogs()
        C_Timer.After(0, function() RefreshEquipmentRows(pane) end)
    end
end

function M:ShowStats()
    self:SetMode("stats")
end

function M:HideAll()
    self:ShowStats()
end

function M:Refresh()
    SkinEquipmentButton(PaperDollFrameEquipSet)
    SkinEquipmentButton(PaperDollFrameSaveSet)
    if self.mode == "title" then StripTitlePane(PaperDollFrame.TitleManagerPane) end
    if self.mode == "equipment" then RefreshEquipmentRows(PaperDollFrame.EquipmentManagerPane) end
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
