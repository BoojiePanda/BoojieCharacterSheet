local _, BCS = ...
local M = {}
BCS:RegisterModule("CharacterFrame", M)

local function OpenSettings()
    if BCS.ToggleSettings then BCS.ToggleSettings() end
end

function M:CreateSettingsButton()
    if self.settingsButton then return end
    local button = CreateFrame("Button", "BoojieCharacterSheetSettingsButton", CharacterFrame)
    button:SetSize(18, 18)
    button:SetPoint("TOPRIGHT", CharacterFrameCloseButton, "TOPLEFT", -3, -1)
    button:SetFrameLevel(CharacterFrameCloseButton:GetFrameLevel() + 1)
    local texture = button:CreateTexture(nil, "ARTWORK")
    texture:SetAllPoints(); texture:SetTexture("Interface\\Buttons\\UI-OptionsButton")
    button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Boojie Character Sheet settings", 1, 0.553, 0.631)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", GameTooltip_Hide)
    button:SetScript("OnClick", function() OpenSettings(); PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON) end)
    self.settingsButton = button
end

local function SavePosition(frame, key)
    local point, _, relativePoint, x, y = frame:GetPoint(1)
    BCS.charDB[key] = { point = point or "TOPLEFT", relativePoint = relativePoint or point or "TOPLEFT", x = x or 0, y = y or 0 }
end

local function CharacterIdentityText()
    local name = UnitName("player") or ""
    local level = UnitLevel("player") or 0
    return name .. " Lvl " .. level
end

function M:UpdateIdentityHeader()
    local nameText = CharacterFrameTitleText or CharacterFrame.TitleText
    if nameText then
        nameText:ClearAllPoints()
        nameText:SetPoint("TOPLEFT", CharacterFrame, "TOPLEFT", 24, -8)
        nameText:SetPoint("TOPRIGHT", CharacterFrame, "TOPRIGHT", -82, -8)
        nameText:SetJustifyH("CENTER")
        nameText:SetText(CharacterIdentityText())
        BCS.modules.Fonts:Apply(nameText, "characterNameSize")
    end
    if CharacterLevelText then
        CharacterLevelText:Hide()
        if not CharacterLevelText._bcsHideHook then
            CharacterLevelText._bcsHideHook = true
            hooksecurefunc(CharacterLevelText, "Show", function(text) text:Hide() end)
        end
    end
end

function M:UpdateGuildHeader()
    if not self.guildText then
        local text = CharacterFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        text:SetPoint("TOPLEFT", CharacterFrame, "TOPLEFT", 24, -26)
        text:SetPoint("TOPRIGHT", CharacterFrame, "TOPRIGHT", -82, -26)
        text:SetHeight(14)
        text:SetJustifyH("CENTER")
        self.guildText = text
    end
    local guildName, guildRank = GetGuildInfo("player")
    if guildName and guildName ~= "" then
        self.guildText:SetText(guildRank and guildRank ~= "" and (guildName .. " - " .. guildRank) or guildName)
        BCS.modules.Fonts:Apply(self.guildText, "guildSize")
        self.guildText:SetHeight(math.max(14, BCS:GetTypography("guildSize") + 2))
        self.guildText:Show()
    else
        self.guildText:SetText("")
        self.guildText:Hide()
    end
end

function M:MakeMovable()
    CharacterFrame:SetMovable(true); CharacterFrame:SetClampedToScreen(true); CharacterFrame:EnableMouse(true)
    CharacterFrame:SetUserPlaced(true)
    if self.movable then return end
    CharacterFrame:RegisterForDrag("LeftButton")
    local function StartDrag(frame)
        if not InCombatLockdown() and not frame._bcsDirectMoving then
            frame._bcsDirectMoving = true
            frame:StartMoving()
        end
    end
    local function StopDrag(frame)
        if not frame._bcsDirectMoving then return end
        frame:StopMovingOrSizing(); frame:SetUserPlaced(true); SavePosition(frame, "characterFramePosition")
        frame._bcsDirectMoving = nil
    end
    CharacterFrame:HookScript("OnDragStart", StartDrag)
    CharacterFrame:HookScript("OnDragStop", StopDrag)

    local titleContainer = CharacterFrame.TitleContainer
    if titleContainer and titleContainer.HookScript then
        titleContainer:EnableMouse(true); titleContainer:RegisterForDrag("LeftButton")
        function titleContainer:GetMAEle() return CharacterFrame end
        titleContainer:HookScript("OnMouseDown", function(_, button) if button == "LeftButton" then StartDrag(CharacterFrame) end end)
        titleContainer:HookScript("OnMouseUp", function(_, button) if button == "LeftButton" then StopDrag(CharacterFrame) end end)
        titleContainer:HookScript("OnDragStart", function() StartDrag(CharacterFrame) end)
        titleContainer:HookScript("OnDragStop", function() StopDrag(CharacterFrame) end)
    end
    self.movable = true
end

function M:LayoutTabs()
    for _, name in ipairs({ "ReputationFrame", "TokenFrame" }) do
        local frame = _G[name]
        if frame then
            frame:ClearAllPoints(); frame:SetPoint("TOPLEFT", CharacterFrame, "TOPLEFT", 10, -38)
            frame:SetPoint("BOTTOMRIGHT", CharacterFrame, "BOTTOMRIGHT", -10, 40)
            if frame.ScrollBox then
                frame.ScrollBox:ClearAllPoints(); frame.ScrollBox:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -44)
                frame.ScrollBox:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -32, 12)
            end
            if frame.ScrollBar then
                frame.ScrollBar:ClearAllPoints(); frame.ScrollBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -48)
                frame.ScrollBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 16)
            end
        end
    end
end

local function ShowTransmogUnavailable(reason)
    local message = "The Blizzard Transmogrification window could not be opened"
    if reason then message = message .. " (" .. tostring(reason) .. ")" end
    BCS:Print(message .. ".")
end

function M:CreateTransmogButton()
    if self.transmogButton or not PaperDollSidebarTabs then return end
    local button = CreateFrame("CheckButton", "BoojieCharacterSheetTransmogButton", PaperDollSidebarTabs)
    button:SetSize(26, 26)
    button:RegisterForClicks("LeftButtonUp")

    button.Icon = button:CreateTexture(nil, "ARTWORK")
    button.Icon:SetPoint("CENTER")
    button.Icon:SetSize(22, 22)
    button.Icon:SetAtlas("transmog-icon-ui", false)

    button:SetScript("OnEnter", function(current)
        GameTooltip:SetOwner(current, "ANCHOR_RIGHT")
        GameTooltip:SetText("Transmogrification", 1, 0.553, 0.631)
        GameTooltip:AddLine("Open Blizzard's Transmogrification window and switch between your saved outfits.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", GameTooltip_Hide)
    button:SetScript("OnClick", function()
        if InCombatLockdown() then
            if UIErrorsFrame then UIErrorsFrame:AddMessage(ERR_AFFECTING_COMBAT or "You cannot do that while in combat.", 1, 0.15, 0.15) end
            return
        end

        if C_AddOns and not C_AddOns.IsAddOnLoaded("Blizzard_Transmog") then
            local loaded, reason = C_AddOns.LoadAddOn("Blizzard_Transmog")
            if not loaded then ShowTransmogUnavailable(reason); return end
        end
        local transmogFrame = _G.TransmogFrame
        if not transmogFrame then ShowTransmogUnavailable(); return end

        local sidePanels = BCS.modules.SidePanels
        if sidePanels and sidePanels.HideAll then sidePanels:HideAll() end
        local settings = BCS.modules.Settings
        if settings and settings.window then settings.window:Hide() end
        ToggleFrame(transmogFrame)
    end)

    self.transmogButton = button
    if BCS.modules.Theme then BCS.modules.Theme:SkinSidebarIcon(button) end
end

function M:LayoutSidebarIcons()
    self:CreateTransmogButton()
    local tabs = { PaperDollSidebarTab1, PaperDollSidebarTab2, PaperDollSidebarTab3, self.transmogButton }
    local previous
    for _, tab in ipairs(tabs) do
        if tab then
            tab:ClearAllPoints(); tab:SetSize(26, 26)
            if previous then tab:SetPoint("LEFT", previous, "RIGHT", 6, 0)
            else tab:SetPoint("TOPRIGHT", CharacterFrame, "TOPRIGHT", -158, -51) end
            previous = tab
        end
    end
end

function M:Apply()
    if not CharacterFrame then return end
    CharacterFrame:SetMovable(true); CharacterFrame:SetClampedToScreen(true); CharacterFrame:EnableMouse(true)
    if UIPanelWindows and UIPanelWindows.CharacterFrame then
        UIPanelWindows.CharacterFrame.width = 870
        UIPanelWindows.CharacterFrame.height = 650
    end
    CharacterFrame:SetSize(870, 650)
    local saved = BCS.charDB.characterFramePosition
    if saved then
        CharacterFrame:ClearAllPoints()
        CharacterFrame:SetPoint(saved.point, UIParent, saved.relativePoint, saved.x, saved.y)
    end
    if CharacterFrameBg then
        CharacterFrameBg:ClearAllPoints()
        CharacterFrameBg:SetPoint("TOPLEFT", CharacterFrame, "TOPLEFT", 0, 0)
        CharacterFrameBg:SetPoint("BOTTOMRIGHT", CharacterFrame, "BOTTOMRIGHT", 0, 0)
    end
    local leftSlots = { CharacterHeadSlot, CharacterNeckSlot, CharacterShoulderSlot, CharacterBackSlot,
        CharacterChestSlot, CharacterShirtSlot, CharacterTabardSlot, CharacterWristSlot }
    local rightSlots = { CharacterHandsSlot, CharacterWaistSlot, CharacterLegsSlot, CharacterFeetSlot,
        CharacterFinger0Slot, CharacterFinger1Slot, CharacterTrinket0Slot, CharacterTrinket1Slot }
    local gap = math.max(10, (BCS.charDB.equipmentTopPadding or 0) + (BCS.charDB.equipmentBottomPadding or 0))
    if leftSlots[1] then
        leftSlots[1]:ClearAllPoints(); leftSlots[1]:SetPoint("TOPLEFT", CharacterFrame, "TOPLEFT", 20, -60)
        for index = 2, #leftSlots do
            leftSlots[index]:ClearAllPoints(); leftSlots[index]:SetPoint("TOPLEFT", leftSlots[index - 1], "BOTTOMLEFT", 0, -gap)
        end
    end
    if rightSlots[1] then
        rightSlots[1]:ClearAllPoints(); rightSlots[1]:SetPoint("TOPLEFT", CharacterFrame, "TOPLEFT", 555, -60)
        for index = 2, #rightSlots do
            rightSlots[index]:ClearAllPoints(); rightSlots[index]:SetPoint("TOPLEFT", rightSlots[index - 1], "BOTTOMLEFT", 0, -gap)
        end
    end
    if CharacterMainHandSlot then
        CharacterMainHandSlot:ClearAllPoints(); CharacterMainHandSlot:SetPoint("BOTTOMLEFT", CharacterFrame, "BOTTOMLEFT", 244, 47)
    end
    if CharacterSecondaryHandSlot then
        CharacterSecondaryHandSlot:ClearAllPoints(); CharacterSecondaryHandSlot:SetPoint("LEFT", CharacterMainHandSlot, "RIGHT", 58, 0)
    end
    if CharacterModelScene then
        CharacterModelScene:ClearAllPoints()
        CharacterModelScene:SetPoint("TOPLEFT", CharacterFrame, "TOPLEFT", 145, -52)
        CharacterModelScene:SetPoint("BOTTOMRIGHT", CharacterFrame, "BOTTOMRIGHT", -390, 58)
        local showModel = BCS.charDB.liveCharacterViewEnabled ~= false
        CharacterModelScene:SetShown(showModel)
        if CharacterModelScene.ControlFrame then CharacterModelScene.ControlFrame:SetShown(showModel) end
    end
    self:LayoutTabs(); self:LayoutSidebarIcons(); self:MakeMovable()
    BCS.modules.Theme:Refresh()
    self:UpdateIdentityHeader()
    self:UpdateGuildHeader()
    self:CreateSettingsButton()
end

function M:ScheduleApply()
    if self.layoutTimer then self.layoutTimer:Cancel() end
    self.layoutTimer = C_Timer.NewTimer(0.05, function()
        self.layoutTimer = nil
        if CharacterFrame and CharacterFrame:IsShown() then self:Apply(); BCS:Refresh() end
    end)
end

function M:Initialize()
    BCS:WhenCharacterUIReady(function()
        self:Apply()
        CharacterFrame:HookScript("OnShow", function()
            self:Apply()
            self:ScheduleApply()
        end)
        if type(CharacterFrame_ShowSubFrame) == "function" then
            hooksecurefunc("CharacterFrame_ShowSubFrame", function()
                self:Apply()
                self:ScheduleApply()
            end)
        end
        local identityEvents = CreateFrame("Frame")
        identityEvents:RegisterEvent("PLAYER_LEVEL_UP")
        identityEvents:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
        identityEvents:RegisterEvent("UNIT_NAME_UPDATE")
        identityEvents:RegisterEvent("PLAYER_GUILD_UPDATE")
        identityEvents:RegisterEvent("GUILD_ROSTER_UPDATE")
        identityEvents:SetScript("OnEvent", function(_, event, unit)
            if CharacterFrame:IsShown() and (event ~= "PLAYER_SPECIALIZATION_CHANGED" or not unit or unit == "player") then
                self:UpdateIdentityHeader(); self:UpdateGuildHeader()
            end
        end)
        self.identityEvents = identityEvents
    end)
end
function M:Refresh() self:Apply() end
