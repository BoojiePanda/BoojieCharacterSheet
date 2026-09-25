local _, BCS = ...
local M = {}
BCS:RegisterModule("ReputationCurrency", M)

local function ElvUIStatusBarTexture()
    if not BCS.charDB.useElvUIReputationTexture then return nil end
    local elvUI = _G.ElvUI
    local engine = type(elvUI) == "table" and elvUI[1]
    return engine and engine.media and engine.media.normTex or nil
end

local function StyleReputationBar(content)
    local bar = content and content.ReputationBar
    if not bar or not bar.SetStatusBarTexture then return end
    if not bar._bcsBlizzardTexture then
        local fill = bar:GetStatusBarTexture()
        bar._bcsBlizzardTexture = fill and fill:GetTexture() or "Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar"
        bar._bcsLeftTextureAlpha = bar.LeftTexture and bar.LeftTexture:GetAlpha() or 1
        bar._bcsRightTextureAlpha = bar.RightTexture and bar.RightTexture:GetAlpha() or 1
    end
    local texture = ElvUIStatusBarTexture()
    bar:SetStatusBarTexture(texture or bar._bcsBlizzardTexture)
    if bar.LeftTexture then bar.LeftTexture:SetAlpha(texture and 0 or bar._bcsLeftTextureAlpha) end
    if bar.RightTexture then bar.RightTexture:SetAlpha(texture and 0 or bar._bcsRightTextureAlpha) end
end

local function StyleRow(row)
    local data = row.GetElementData and row:GetElementData() or row.elementData
    local content = row.Content or row
    local toggle = row.ToggleCollapseButton or row.ExpandOrCollapseButton or row.ToggleButton or row.ExpandButton or row.CollapseButton
    local collapseAtlas = row.Right
    local isHeader = data and (data.isHeader or data.isCategory or data.isExpansion)
    isHeader = isHeader or toggle or collapseAtlas
    StyleReputationBar(content)
    local fontStrings = row._bcsFontStrings
    if not fontStrings then
        fontStrings = {}
        local seen = {}
        for _, key in ipairs({ "Name", "name", "Label", "label", "Title", "title", "Text", "text" }) do
            local fontString = row[key]
            if fontString and fontString.GetObjectType and fontString:GetObjectType() == "FontString" and not seen[fontString] then
                seen[fontString] = true; fontStrings[#fontStrings + 1] = fontString
            end
        end
        for _, region in ipairs({ row:GetRegions() }) do
            if region.GetObjectType and region:GetObjectType() == "FontString" and not seen[region] then
                seen[region] = true; fontStrings[#fontStrings + 1] = region
            end
        end
        row._bcsFontStrings = fontStrings
    end
    local color = isHeader and BCS.charDB.accentColor or BCS.charDB.textColor
    for _, fontString in ipairs(fontStrings) do
        BCS.modules.Fonts:Apply(fontString, isHeader and "reputationCurrencyHeaderSize" or "miscTextSize")
        fontString:SetTextColor(color[1], color[2], color[3], color[4] or 1)
    end
    local accountWideIcon = content.AccountWideIcon
    if accountWideIcon then
        if not content._bcsAccountWideIcon then
            local icon = content:CreateTexture(nil, "OVERLAY", nil, 7)
            icon:SetAtlas("warbands-icon", true)
            icon:ClearAllPoints()
            icon:SetAllPoints(accountWideIcon)
            content._bcsAccountWideIcon = icon
        end
        local showWarband = data and (data.isAccountTransferable or data.isAccountWide)
        content._bcsAccountWideIcon:SetShown(not not showWarband)
        content._bcsAccountWideIcon:SetAlpha(1)
    end
    if toggle then
        local normal = toggle.GetNormalTexture and toggle:GetNormalTexture()
        local atlas = normal and normal.GetAtlas and normal:GetAtlas()
        local expanded = data and (data.isExpanded or data.isCollapsed == false)
        local header = toggle.GetHeader and toggle:GetHeader()
        if header and header.IsCollapsed then expanded = not header:IsCollapsed() end
        if not expanded and atlas then
            local lower = atlas:lower(); expanded = lower:find("minus") or lower:find("collapse")
        end
        if not toggle._bcsSkin then
            for _, region in ipairs({ toggle:GetRegions() }) do
                if region:GetObjectType() == "Texture" then region:SetAlpha(0) end
            end
            toggle:SetSize(16, 16)
            toggle._bcsSymbol = toggle:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            toggle._bcsSymbol:SetPoint("CENTER", 0, 0)
            toggle._bcsSymbol:SetDrawLayer("OVERLAY", 7)
            BCS.modules.Fonts:Apply(toggle._bcsSymbol, "miscTextSize")
            toggle._bcsSkin = true
        end
        local accent = BCS.charDB.accentColor
        toggle._bcsSymbol:SetText(expanded and "−" or "+")
        toggle._bcsSymbol:SetTextColor(accent[1], accent[2], accent[3], 1)
    end
    if collapseAtlas then
        local atlas = collapseAtlas.GetAtlas and collapseAtlas:GetAtlas()
        local expanded = data and (data.isExpanded or data.isCollapsed == false)
        if atlas then
            local lower = atlas:lower()
            if lower:find("minus") or lower:find("collapse") then expanded = true end
        end
        collapseAtlas:SetAlpha(0)
        if row.HighlightRight then row.HighlightRight:SetAlpha(0) end
        if not row._bcsCollapseSymbol then
            local symbol = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            symbol:SetPoint("RIGHT", row, "RIGHT", -5, 0)
            symbol:SetDrawLayer("OVERLAY", 7)
            BCS.modules.Fonts:Apply(symbol, "miscTextSize")
            row._bcsCollapseSymbol = symbol
        end
        local accent = BCS.charDB.accentColor
        row._bcsCollapseSymbol:SetText(expanded and "−" or "+")
        row._bcsCollapseSymbol:SetTextColor(accent[1], accent[2], accent[3], 1)
        row._bcsCollapseSymbol:Show()
    elseif row._bcsCollapseSymbol then
        row._bcsCollapseSymbol:Hide()
    end
    if not row._bcsHoverStyleHook then
        row._bcsHoverStyleHook = true
        row:HookScript("OnEnter", StyleRow)
        row:HookScript("OnLeave", StyleRow)
    end
end

local function StyleVisible(scrollBox)
    if not scrollBox or not scrollBox.ForEachFrame then return end
    scrollBox:ForEachFrame(StyleRow)
end

local function HookScrollBox(scrollBox)
    if not scrollBox or scrollBox._bcsStyleHook then return end
    scrollBox._bcsStyleHook = true
    if scrollBox.Update then
        hooksecurefunc(scrollBox, "Update", function(box)
            if box:IsShown() and CharacterFrame:IsShown() then StyleVisible(box) end
        end)
    end
    scrollBox:HookScript("OnShow", StyleVisible)
end

local function RaiseDropdown(frame)
    local dropdown = frame and frame.filterDropdown
    if not dropdown then return end
    dropdown:ClearAllPoints()
    if frame == TokenFrame and frame.CurrencyTransferLogToggleButton then
        frame.CurrencyTransferLogToggleButton:ClearAllPoints()
        frame.CurrencyTransferLogToggleButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -14, -8)
        dropdown:SetPoint("TOPRIGHT", frame.CurrencyTransferLogToggleButton, "TOPLEFT", -8, 0)
    elseif frame == TokenFrame then
        dropdown:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -130, -8)
    else
        dropdown:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -14, -8)
    end
    dropdown:SetFrameStrata("DIALOG"); dropdown:SetFrameLevel(700)
    if not frame._bcsFilterHeader then
        local header = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        header:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -4); header:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -4)
        header:SetHeight(34); header:SetFrameLevel(math.max(0, frame:GetFrameLevel()))
        header:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        frame._bcsFilterHeader = header
    end
    local border = BCS.charDB.borderColor
    frame._bcsFilterHeader:SetBackdropColor(0, 0, 0, 1)
    frame._bcsFilterHeader:SetBackdropBorderColor(border[1], border[2], border[3], border[4] or 1)
    if not dropdown._bcsRaiseHook then
        dropdown:HookScript("OnMouseDown", function()
            C_Timer.After(0, function()
                for index = 1, 3 do
                    local menu = _G["DropDownList" .. index]
                    if menu then menu:SetFrameStrata("TOOLTIP"); menu:SetFrameLevel(2000) end
                end
            end)
        end)
        dropdown._bcsRaiseHook = true
    end
end

function M:Refresh()
    RaiseDropdown(ReputationFrame); RaiseDropdown(TokenFrame)
    StyleVisible(ReputationFrame and (ReputationFrame._bcsScrollBox or ReputationFrame.ScrollBox))
    StyleVisible(TokenFrame and TokenFrame.ScrollBox)
end


function M:Initialize()
    BCS:WhenCharacterUIReady(function()
        HookScrollBox(ReputationFrame and (ReputationFrame._bcsScrollBox or ReputationFrame.ScrollBox))
        HookScrollBox(TokenFrame and TokenFrame.ScrollBox)
        self:Refresh()
    end)
end
