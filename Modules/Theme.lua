local _, BCS = ...
local M = {}
BCS:RegisterModule("Theme", M)

local function HideTextures(frame)
    if not frame or frame._bcsTexturesHidden then return end
    for _, region in ipairs({ frame:GetRegions() }) do
        if region and region.GetObjectType and region:GetObjectType() == "Texture" then region:SetAlpha(0) end
    end
    if frame.NineSlice then
        for _, region in pairs(frame.NineSlice) do
            if type(region) == "table" and region.SetAlpha then region:SetAlpha(0) end
        end
    end
    frame._bcsTexturesHidden = true
end

local function Colors()
    local bg, border = BCS.charDB.backgroundColor, BCS.charDB.borderColor
    return bg[1], bg[2], bg[3], BCS.charDB.backgroundOpacity * (bg[4] or 1),
        border[1], border[2], border[3], BCS.charDB.borderOpacity * (border[4] or 1)
end

local function PixelLine(parent, point1, relative1, point2, relative2)
    local line = parent:CreateTexture(nil, "OVERLAY", nil, 7)
    line:SetColorTexture(1, 1, 1, 1)
    line:SetPoint(point1, parent, relative1, 0, 0)
    line:SetPoint(point2, parent, relative2, 0, 0)
    return line
end

local function CreatePixelBorder(button, key)
    if button[key] then return button[key] end
    local overlay = CreateFrame("Frame", nil, button)
    overlay:SetAllPoints(button)
    overlay:SetFrameLevel(button:GetFrameLevel() + 20)
    local lines = {
        PixelLine(overlay, "TOPLEFT", "TOPLEFT", "TOPRIGHT", "TOPRIGHT"),
        PixelLine(overlay, "BOTTOMLEFT", "BOTTOMLEFT", "BOTTOMRIGHT", "BOTTOMRIGHT"),
        PixelLine(overlay, "TOPLEFT", "TOPLEFT", "BOTTOMLEFT", "BOTTOMLEFT"),
        PixelLine(overlay, "TOPRIGHT", "TOPRIGHT", "BOTTOMRIGHT", "BOTTOMRIGHT"),
    }
    if PixelUtil then
        PixelUtil.SetHeight(lines[1], 1); PixelUtil.SetHeight(lines[2], 1)
        PixelUtil.SetWidth(lines[3], 1); PixelUtil.SetWidth(lines[4], 1)
    else
        lines[1]:SetHeight(1); lines[2]:SetHeight(1); lines[3]:SetWidth(1); lines[4]:SetWidth(1)
    end
    overlay.lines = lines
    button[key] = overlay
    return overlay
end

local function SetPixelBorderColor(overlay, r, g, b, a)
    overlay:SetFrameLevel(overlay:GetParent():GetFrameLevel() + 20)
    for _, line in ipairs(overlay.lines) do line:SetColorTexture(r, g, b, a or 1); line:Show() end
    overlay:Show()
end

function M:CreateSkin()
    if self.skin then return end
    local skin = CreateFrame("Frame", "BoojieCharacterSheetSkin", CharacterFrame, "BackdropTemplate")
    skin:SetAllPoints(CharacterFrame); skin:SetFrameLevel(0)
    skin:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 2 })
    local top = skin:CreateTexture(nil, "ARTWORK"); top:SetHeight(46)
    top:SetPoint("TOPLEFT", 2, -2); top:SetPoint("TOPRIGHT", -2, -2)
    top:SetColorTexture(0.12, 0.045, 0.09, 0.98); skin.top = top
    local accent = skin:CreateTexture(nil, "ARTWORK"); accent:SetHeight(1)
    accent:SetPoint("TOPLEFT", 6, -46); accent:SetPoint("TOPRIGHT", -6, -46)
    accent:SetColorTexture(1, 0.553, 0.631, 0.8)
    self.skin = skin
end

function M:SkinSlot(button, slotID)
    if not button then return end
    local icon = button.icon or button.Icon or button.IconTexture or (button.GetName and _G[(button:GetName() or "") .. "IconTexture"])
    if icon then
        icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        if icon.GetNumMaskTextures and icon.RemoveMaskTexture then
            while icon:GetNumMaskTextures() > 0 do
                local mask = icon:GetMaskTexture(1)
                if not mask then break end
                icon:RemoveMaskTexture(mask)
            end
        end
    end
    for _, region in ipairs({ button:GetRegions() }) do
        if region and region.GetObjectType and region:GetObjectType() == "Texture" and region ~= icon then
            region:SetAlpha(0)
        end
    end
    for _, key in ipairs({ "IconBorder", "IconOverlay", "IconOverlay2", "SlotArt", "Background" }) do
        local region = button[key]
        if region and region.SetAlpha then region:SetAlpha(0); region:Hide() end
    end
    if button.IconBorder and not button.IconBorder._bcsShowHook then
        button.IconBorder._bcsShowHook = true
        hooksecurefunc(button.IconBorder, "Show", function(border) border:Hide() end)
    end
    local normal = button:GetNormalTexture(); if normal then normal:SetAlpha(0) end
    local quality = GetInventoryItemQuality("player", slotID)
    local r, g, b = 0.28, 0.28, 0.34
    if quality then r, g, b = C_Item.GetItemQualityColor(quality) end
    SetPixelBorderColor(CreatePixelBorder(button, "_bcsPixelBorder"), r, g, b, 1)
end

function M:SkinSidebarIcon(button)
    if not button then return end
    local icon = button.Icon or button.icon or button.IconTexture
    if icon then
        icon:ClearAllPoints()
        icon:SetPoint("CENTER")
        icon:SetSize(22, 22)
    end
    for _, key in ipairs({ "TabBg", "Hider", "Highlight", "CheckedTexture", "SelectedTexture", "ActiveTexture", "Border", "IconBorder" }) do
        if button[key] and button[key].SetAlpha then button[key]:SetAlpha(0) end
    end
    local border = BCS.charDB.borderColor
    SetPixelBorderColor(CreatePixelBorder(button, "_bcsPixelBorder"), border[1], border[2], border[3], border[4] or 1)
end

function M:SkinTab(tab)
    if not tab or tab._bcsSkin then return end
    local bg = CreateFrame("Frame", nil, tab, "BackdropTemplate")
    bg:SetAllPoints(); bg:SetFrameLevel(math.max(0, tab:GetFrameLevel() - 1))
    bg:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    bg:SetBackdropColor(0.025, 0.025, 0.035, 0.96); bg:SetBackdropBorderColor(0.28, 0.18, 0.28, 1)
    tab._bcsSkin = bg
end

function M:SetTabStyle(tab, enabled)
    if not tab then return end
    self:SkinTab(tab)
    tab._bcsSkin:SetShown(enabled)
    for _, region in ipairs({ tab:GetRegions() }) do
        if region and region.GetObjectType and region:GetObjectType() == "Texture" then region:SetAlpha(enabled and 0 or 1) end
    end
end

function M:SkinCloseButton()
    local button = CharacterFrameCloseButton
    if not button or button._bcsSkinned then return end
    for _, region in ipairs({ button:GetRegions() }) do
        if region and region.GetObjectType and region:GetObjectType() == "Texture" then region:SetAlpha(0) end
    end
    local bg = CreateFrame("Frame", nil, button, "BackdropTemplate")
    bg:SetAllPoints(); bg:SetFrameLevel(math.max(0, button:GetFrameLevel() - 1))
    bg:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    bg:SetBackdropColor(0.03, 0.03, 0.04, 1); bg:SetBackdropBorderColor(1, 0.553, 0.631, 0.8)
    local x = button:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    x:SetPoint("CENTER", 0, 1); x:SetText("×"); x:SetTextColor(1, 0.553, 0.631)
    button._bcsSkinned = true
end

function M:Refresh()
    if not CharacterFrame then return end
    self:CreateSkin()
    HideTextures(CharacterFrame); HideTextures(CharacterFrameInset); HideTextures(CharacterFrameInsetRight)
    HideTextures(CharacterModelScene)
    if CharacterModelScene and CharacterModelScene.backdrop then CharacterModelScene.backdrop:Hide() end
    if CharacterFrameBg then CharacterFrameBg:SetAlpha(0) end
    if CharacterFrame.PortraitContainer then CharacterFrame.PortraitContainer:Hide() end
    for _, frame in ipairs({ CharacterModelFrameBackgroundTopLeft, CharacterModelFrameBackgroundTopRight,
        CharacterModelFrameBackgroundBotLeft, CharacterModelFrameBackgroundBotRight, CharacterModelFrameBackgroundOverlay }) do
        if frame then frame:SetAlpha(0) end
    end
    local br, bg, bb, ba, rr, rg, rb, ra = Colors()
    self.skin:SetBackdropColor(br, bg, bb, ba); self.skin:SetBackdropBorderColor(rr, rg, rb, ra)
    local accent = BCS.charDB.accentColor
    self.skin.top:SetColorTexture(accent[1] * 0.18, accent[2] * 0.08, accent[3] * 0.15, 0.98)
    for name, slotID in pairs(BCS.modules.EquipmentSlots and BCS.modules.EquipmentSlots.slots or {}) do self:SkinSlot(_G[name], slotID) end
    for index = 1, 3 do self:SkinSidebarIcon(_G["PaperDollSidebarTab" .. index]) end
    local characterModule = BCS.modules.CharacterFrame
    if characterModule then self:SkinSidebarIcon(characterModule.transmogButton) end
    for index = 1, 5 do self:SetTabStyle(_G["CharacterFrameTab" .. index], BCS.charDB.restrainedTabsEnabled) end
    self:SkinCloseButton()
end
