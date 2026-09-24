local _, BCS = ...
local M = { controls = {} }
BCS:RegisterModule("Settings", M)

local function SettingTable()
    return BCS.db.typography.useAccountWide and BCS.db.typography or BCS.charDB.typography
end

local function SliderTable(key)
    if key == "equipmentTopPadding" or key == "equipmentBottomPadding" or key == "gearTooltipScale" then return BCS.charDB end
    return SettingTable()
end

local function SliderDefault(key)
    return BCS.defaults.typography[key] or BCS.characterDefaults[key] or 0
end

local function SaveWindowPosition(frame)
    local point, _, relativePoint, x, y = frame:GetPoint(1)
    BCS.charDB.settingsPosition = { point = point or "TOPLEFT", relativePoint = relativePoint or point or "TOPLEFT", x = x or 0, y = y or 0 }
end

local function SetSettingsSnapVisual(frame)
    local snapped = BCS.db.settingsWindowSnapped
    frame.snapButton.check:SetShown(snapped)
    frame.snapButton:SetBackdropBorderColor(snapped and 0.55 or 0.48, snapped and 1 or 0.40, snapped and 0.68 or 0.48, 1)
end

local function SnapSettings(frame)
    frame:SetClampedToScreen(false)
    frame:ClearAllPoints(); frame:SetPoint("TOPLEFT", CharacterFrame, "TOPRIGHT", 8, 0)
    BCS.charDB.settingsPosition = nil; SetSettingsSnapVisual(frame)
end

local function UnsnapSettings(frame)
    local left, top = frame:GetLeft(), frame:GetTop()
    frame:ClearAllPoints()
    frame:SetClampedToScreen(true)
    if left and top then frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
    else frame:SetPoint("TOPLEFT", CharacterFrame, "TOPRIGHT", 8, 0) end
    SetSettingsSnapVisual(frame)
end

local function SkinScrollBar(scroll)
    local bar = scroll.ScrollBar or _G[(scroll:GetName() or "") .. "ScrollBar"]
    if not bar then return end
    local thumb = bar.GetThumbTexture and bar:GetThumbTexture()
    bar:ClearAllPoints(); bar:SetPoint("TOPRIGHT", scroll, "TOPRIGHT", -2, -2); bar:SetPoint("BOTTOMRIGHT", scroll, "BOTTOMRIGHT", -2, 2)
    bar:SetWidth(12)
    for _, region in ipairs({ bar:GetRegions() }) do
        if region:GetObjectType() == "Texture" and region ~= thumb then region:SetAlpha(0) end
    end
    local track = bar:CreateTexture(nil, "BACKGROUND"); track:SetAllPoints(); track:SetColorTexture(0.015, 0.015, 0.022, 0.96)
    if thumb then thumb:SetTexture("Interface\\Buttons\\WHITE8X8"); thumb:SetColorTexture(1, 0.553, 0.631, 0.9); thumb:SetWidth(8) end
    for _, child in ipairs({ bar:GetChildren() }) do
        if child.GetNormalTexture then
            local normal = child:GetNormalTexture(); if normal then normal:SetAlpha(0) end
            child:SetAlpha(0.7)
        end
    end
end

local function SkinControl(frame)
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    frame:SetBackdropColor(0.025, 0.025, 0.035, 0.98)
    frame:SetBackdropBorderColor(1, 0.553, 0.631, 0.7)
end

function M:AddLabel(text, x, y, template)
    local label = self.frame:CreateFontString(nil, "OVERLAY", template or "GameFontHighlightSmall")
    label:SetPoint("TOPLEFT", x, y); label:SetText(text)
    return label
end

function M:AddDivider(y)
    local divider = self.frame:CreateTexture(nil, "ARTWORK")
    divider:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 18, y)
    divider:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -18, y)
    divider:SetHeight(1)
    local accent = BCS.charDB.accentColor
    divider:SetColorTexture(accent[1], accent[2], accent[3], 0.38)
    self.dividers = self.dividers or {}
    self.dividers[#self.dividers + 1] = divider
end

function M:AddCheckbox(label, key, y, accountKey, x)
    local box = CreateFrame("CheckButton", nil, self.frame, "UICheckButtonTemplate")
    box:SetPoint("TOPLEFT", x or 18, y); box:SetSize(22, 22)
    box.Text:SetText(label); box.Text:SetTextColor(0.92, 0.92, 0.92)
    box:SetChecked(accountKey and BCS.db.typography[key] or BCS.charDB[key])
    box:SetScript("OnClick", function(button)
        if accountKey then BCS.db.typography[key] = button:GetChecked() else BCS.charDB[key] = button:GetChecked() end
        BCS:Refresh()
    end)
    self.controls[key] = box
end

function M:AddStatCheckbox(label, key, y, x)
    local box = CreateFrame("CheckButton", nil, self.frame, "UICheckButtonTemplate")
    box:SetPoint("TOPLEFT", x or 18, y); box:SetSize(22, 22)
    box.Text:SetText(label); box.Text:SetTextColor(0.92, 0.92, 0.92)
    box:SetChecked(BCS.charDB.statsSections[key] ~= false)
    box:SetScript("OnClick", function(button)
        BCS.charDB.statsSections[key] = not not button:GetChecked()
        BCS:Refresh()
    end)
    self.controls["stats_" .. key] = box
end

function M:AddSlider(label, key, y, low, high, x, width, showSideLabel)
    if showSideLabel ~= false then self:AddLabel(label, 22, y) end
    local slider = CreateFrame("Slider", "BoojieCharacterSheet" .. key .. "Slider", self.frame, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", x or 270, y + 5); slider:SetSize(width or 410, 16)
    slider:SetMinMaxValues(low, high); slider:SetValueStep(1); slider:SetObeyStepOnDrag(true)
    _G[slider:GetName() .. "Low"]:SetText(tostring(low)); _G[slider:GetName() .. "High"]:SetText(tostring(high))
    slider:SetValue(SliderTable(key)[key] or SliderDefault(key))
    slider:SetScript("OnValueChanged", function(control, value)
        if self.refreshing then return end
        value = math.floor(value + 0.5); SliderTable(key)[key] = value
        _G[control:GetName() .. "Text"]:SetText(label .. ": " .. value)
        BCS:Refresh()
    end)
    _G[slider:GetName() .. "Text"]:SetText(label .. ": " .. math.floor(slider:GetValue() + 0.5))
    self.controls[key] = slider
end

function M:SetEditedColor(color)
    if not self.selectedColorKey then return end
    BCS.charDB[self.selectedColorKey] = { color[1], color[2], color[3], color[4] or 1 }
    BCS:Refresh()
end

function M:OpenColorEditor(key)
    self.selectedColorKey = key
    if not ColorPickerFrame or not ColorPickerFrame.SetupColorPickerAndShow then
        if C_AddOns and C_AddOns.LoadAddOn then C_AddOns.LoadAddOn("Blizzard_ColorPicker") end
    end
    if not ColorPickerFrame or not ColorPickerFrame.SetupColorPickerAndShow then return end
    local original = { unpack(BCS.charDB[key]) }
    local function Changed()
        local r, g, b = ColorPickerFrame:GetColorRGB()
        local a = ColorPickerFrame:GetColorAlpha() or original[4] or 1
        self:SetEditedColor({ r, g, b, a })
    end
    ColorPickerFrame:SetupColorPickerAndShow({
        r = original[1], g = original[2], b = original[3], opacity = original[4] or 1, hasOpacity = true,
        swatchFunc = Changed, opacityFunc = Changed,
        cancelFunc = function() self:SetEditedColor(original) end,
    })
end

function M:AddColor(label, key, x, y)
    local button = CreateFrame("Button", nil, self.frame, "BackdropTemplate")
    button:SetPoint("TOPLEFT", x, y); button:SetSize(150, 28); SkinControl(button)
    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    button.text:SetPoint("LEFT", 28, 0); button.text:SetText(label)
    button.swatch = button:CreateTexture(nil, "ARTWORK"); button.swatch:SetSize(17, 17); button.swatch:SetPoint("LEFT", 6, 0)
    local function RefreshSwatch()
        local color = BCS.charDB[key]; button.swatch:SetColorTexture(color[1], color[2], color[3], 1)
    end
    button:SetScript("OnClick", function()
        self:OpenColorEditor(key)
    end)
    RefreshSwatch(); self.controls[key] = button
end

function M:BuildFontList()
    local list = {}
    for name, path in pairs(BCS.fonts or {}) do list[#list + 1] = { name = name, path = path } end
    table.sort(list, function(a, b) return a.name:lower() < b.name:lower() end)
    return list
end

function M:CurrentFontName(key)
    local current = BCS:GetTypography(key or "font")
    for _, font in ipairs(self.fontList) do if font.path == current then return font.name end end
    return "Friz Quadrata"
end

function M:CreateFontPicker(y, key, label)
    key, label = key or "font", label or "Font face"
    self:AddLabel(label, 22, y)
    local button = CreateFrame("Button", nil, self.frame, "BackdropTemplate")
    button:SetPoint("TOPLEFT", 125, y + 5); button:SetSize(555, 24); SkinControl(button)
    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    button.text:SetPoint("LEFT", 8, 0); button.text:SetPoint("RIGHT", -24, 0); button.text:SetJustifyH("LEFT")
    button.arrow = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    button.arrow:SetPoint("RIGHT", -8, 0); button.arrow:SetText("▼")

    local popup = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    popup:SetPoint("TOPLEFT", button, "BOTTOMLEFT", 0, -2); popup:SetSize(555, 300); SkinControl(popup)
    popup:SetFrameStrata("FULLSCREEN_DIALOG"); popup:SetFrameLevel(1700); popup:Hide()
    local scroll = CreateFrame("ScrollFrame", nil, popup, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 5, -5); scroll:SetPoint("BOTTOMRIGHT", -27, 5)
    local child = CreateFrame("Frame", nil, scroll); child:SetSize(520, math.max(1, #self.fontList) * 22); scroll:SetScrollChild(child)
    for index, font in ipairs(self.fontList) do
        local selected = font
        local entry = CreateFrame("Button", nil, child)
        entry:SetPoint("TOPLEFT", 2, -(index - 1) * 22); entry:SetSize(514, 21)
        entry.text = entry:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        entry.text:SetPoint("LEFT", 5, 0); entry.text:SetText(selected.name)
        entry:SetHighlightTexture("Interface\\Buttons\\WHITE8X8"); entry:GetHighlightTexture():SetVertexColor(1, 0.553, 0.631, 0.18)
        entry:SetScript("OnClick", function()
            SettingTable()[key] = selected.path; button.text:SetText(selected.name); popup:Hide(); BCS:Refresh()
        end)
    end
    button:SetScript("OnClick", function()
        local opening = not popup:IsShown()
        for _, other in pairs(self.fontPopups or {}) do other:Hide() end
        popup:SetShown(opening)
    end)
    button.text:SetText(self:CurrentFontName(key))
    self.fontButtons, self.fontPopups = self.fontButtons or {}, self.fontPopups or {}
    self.fontButtons[key], self.fontPopups[key] = button, popup
end

function M:ShowPage(key, keepPopups)
    if not self.pages or not self.pages[key] then return end
    self.currentPage = key
    local accent = BCS.charDB.accentColor
    for pageKey, page in pairs(self.pages) do
        page.scroll:SetShown(pageKey == key)
        local button = self.pageButtons and self.pageButtons[pageKey]
        if button then
            local selected = pageKey == key
            button:SetBackdropColor(selected and accent[1] * 0.16 or 0.025, selected and accent[2] * 0.16 or 0.025,
                selected and accent[3] * 0.16 or 0.035, 0.98)
            button:SetBackdropBorderColor(selected and accent[1] or 0.24, selected and accent[2] or 0.24,
                selected and accent[3] or 0.30, selected and 0.95 or 1)
            button.text:SetTextColor(selected and accent[1] or 0.82, selected and accent[2] or 0.82,
                selected and accent[3] or 0.82, 1)
        end
    end
    if not keepPopups then
        for _, popup in pairs(self.fontPopups or {}) do popup:Hide() end
        if ColorPickerFrame then ColorPickerFrame:Hide() end
    end
end

function M:CreatePanel()
    local frame = CreateFrame("Frame", "BoojieCharacterSheetSettingsFrame", UIParent, "BackdropTemplate")
    frame:SetSize(720, 650)
    local saved = BCS.charDB.settingsPosition
    if BCS.db.settingsWindowSnapped then frame:SetPoint("TOPLEFT", CharacterFrame, "TOPRIGHT", 8, 0)
    elseif saved then frame:SetPoint(saved.point, UIParent, saved.relativePoint, saved.x, saved.y)
    else frame:SetPoint("TOPLEFT", CharacterFrame, "TOPRIGHT", 8, 0) end
    frame:SetFrameStrata("DIALOG"); frame:SetFrameLevel(500); SkinControl(frame); frame:Hide()
    frame:SetMovable(true); frame:SetClampedToScreen(not BCS.db.settingsWindowSnapped); frame:EnableMouse(true); frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(window)
        if BCS.db.settingsWindowSnapped then
            if not InCombatLockdown() then window._bcsMovingCharacter = true; CharacterFrame:StartMoving() end
        else window:StartMoving() end
    end)
    frame:SetScript("OnDragStop", function(window)
        if window._bcsMovingCharacter then
            CharacterFrame:StopMovingOrSizing(); CharacterFrame:SetUserPlaced(true)
            local point, _, relativePoint, x, y = CharacterFrame:GetPoint(1)
            BCS.charDB.characterFramePosition = { point = point, relativePoint = relativePoint, x = x, y = y }
            window._bcsMovingCharacter = nil
        else window:StopMovingOrSizing(); SaveWindowPosition(window) end
    end)
    self.frame, self.window = frame, frame
    local title = self:AddLabel("Boojie Character Sheet Settings", 18, -16, "GameFontNormalLarge")
    title:SetTextColor(1, 0.553, 0.631)
    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -3, -3); close:SetScript("OnClick", function()
        self:HideAnimated()
        if ColorPickerFrame then ColorPickerFrame:Hide() end
    end)
    local snap = CreateFrame("Button", nil, frame, "BackdropTemplate")
    snap:SetSize(16, 16); snap:SetPoint("RIGHT", close, "LEFT", -3, 0)
    snap:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    snap:SetBackdropColor(0.025, 0.025, 0.035, 1)
    snap.check = snap:CreateTexture(nil, "ARTWORK"); snap.check:SetPoint("TOPLEFT", 3, -3); snap.check:SetPoint("BOTTOMRIGHT", -3, 3)
    snap.check:SetColorTexture(0.55, 1, 0.68, 1); frame.snapButton = snap; SetSettingsSnapVisual(frame)
    snap:SetScript("OnClick", function()
        BCS.db.settingsWindowSnapped = not BCS.db.settingsWindowSnapped
        if BCS.db.settingsWindowSnapped then SnapSettings(frame) else UnsnapSettings(frame); SaveWindowPosition(frame) end
    end)
    snap:SetScript("OnEnter", function(button)
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
        GameTooltip:SetText(BCS.db.settingsWindowSnapped and "Settings snapped" or "Snap settings", BCS.db.settingsWindowSnapped and 0.55 or 1, BCS.db.settingsWindowSnapped and 1 or 0.553, BCS.db.settingsWindowSnapped and 0.68 or 0.631)
        GameTooltip:AddLine(BCS.db.settingsWindowSnapped and "Settings are aligned with the character sheet. Dragging either window moves both together." or "Align Settings beside the character sheet and link their movement.", 1, 1, 1, true)
        GameTooltip:AddLine(BCS.db.settingsWindowSnapped and "Click to unlock independent movement." or "Click again to unlock it.", 1, 0.82, 0.25, true)
        GameTooltip:Show()
    end)
    snap:SetScript("OnLeave", GameTooltip_Hide)
    local line = frame:CreateTexture(nil, "ARTWORK"); line:SetColorTexture(1, 0.553, 0.631, 0.5)
    line:SetPoint("TOPLEFT", 15, -44); line:SetPoint("TOPRIGHT", -15, -44); line:SetHeight(1)

    self.pages, self.pageButtons = {}, {}
    self.dividers = self.dividers or {}
    local function CreatePage(key, height)
        local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -94); scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -5, 8)
        local content = CreateFrame("Frame", nil, scroll); content:SetSize(690, height); scroll:SetScrollChild(content)
        SkinScrollBar(scroll); scroll:Hide()
        self.pages[key] = { scroll = scroll, content = content }
        return content
    end
    local pageSpecs = {
        { "character", "Character Sheet", 72, 180 },
        { "attributes", "Attributes", 260, 160 },
        { "reputation", "Reputation and Currency", 428, 220 },
    }
    for _, spec in ipairs(pageSpecs) do
        local key, label, x, width = unpack(spec)
        local button = CreateFrame("Button", nil, frame, "BackdropTemplate")
        button:SetPoint("TOPLEFT", frame, "TOPLEFT", x, -56); button:SetSize(width, 28); SkinControl(button)
        button.text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        button.text:SetPoint("CENTER"); button.text:SetText(label)
        button:SetScript("OnClick", function() self:ShowPage(key) end)
        self.pageButtons[key] = button
    end
    local navigationLine = frame:CreateTexture(nil, "ARTWORK"); navigationLine:SetColorTexture(1, 0.553, 0.631, 0.35)
    navigationLine:SetPoint("TOPLEFT", 15, -88); navigationLine:SetPoint("TOPRIGHT", -15, -88); navigationLine:SetHeight(1)
    self.dividers[#self.dividers + 1] = navigationLine

    -- Character Sheet page
    self.frame = CreatePage("character", 675)
    self:AddLabel("Live appearance", 18, -18, "GameFontNormal")
    self:AddCheckbox("Show gear labels and item levels", "equipmentLabelsEnabled", -40, false, 18)
    self:AddCheckbox("Show live character view", "liveCharacterViewEnabled", -40, false, 280)
    self:AddCheckbox("Use restrained tab styling", "restrainedTabsEnabled", -40, false, 500)
    self:AddDivider(-67)

    self:AddLabel("Gear details", 18, -80, "GameFontNormal")
    self:AddCheckbox("Item name", "gearItemNameEnabled", -104, false, 18)
    self:AddCheckbox("Upgrade level", "gearUpgradeLevelEnabled", -104, false, 175)
    self:AddCheckbox("Hide max upgrade (6/6)", "gearHideMaxUpgrade", -104, false, 330)
    self:AddCheckbox("Color upgrade tracks", "gearUpgradeTrackColorsEnabled", -104, false, 525)
    self:AddCheckbox("Gem name", "gemNameEnabled", -132, false, 18)
    self:AddCheckbox("Gem icon", "gemIconEnabled", -132, false, 175)
    self:AddCheckbox("Enchant", "enchantEnabled", -132, false, 330)
    self:AddDivider(-159)

    self:AddLabel("Equipment spacing", 18, -172, "GameFontNormal")
    self:AddSlider("Top padding", "equipmentTopPadding", -212, 0, 12, 28, 300, false)
    self:AddSlider("Bottom padding", "equipmentBottomPadding", -212, 0, 12, 372, 300, false)
    self:AddSlider("Gear tooltip size (%)", "gearTooltipScale", -260, 75, 150, 200, 300, false)
    self:AddDivider(-290)

    self:AddLabel("Typography", 18, -304, "GameFontNormal")
    self:AddCheckbox("Use account-wide font and sizes", "useAccountWide", -326, true)
    self.fontList = self:BuildFontList(); self:CreateFontPicker(-356, "font")
    self:AddSlider("Character name font size", "characterNameSize", -398, 9, 32, 28, 300, false)
    self:AddSlider("Guild name font size", "guildSize", -398, 9, 28, 372, 300, false)
    self:AddSlider("Gear name font size", "gearNameSize", -450, 8, 24, 28, 300, false)
    self:AddSlider("Gear detail font size", "slotLabelSize", -450, 8, 20, 372, 300, false)
    self:AddDivider(-484)

    self:AddLabel("Panel appearance", 18, -498, "GameFontNormal")
    self:AddLabel("Background opacity", 22, -526)
    local opacity = CreateFrame("Slider", "BoojieCharacterSheetOpacitySlider", self.frame, "OptionsSliderTemplate")
    opacity:SetPoint("TOPLEFT", 270, -521); opacity:SetSize(410, 16); opacity:SetMinMaxValues(20, 100); opacity:SetValueStep(1)
    opacity:SetValue(BCS.charDB.backgroundOpacity * 100)
    opacity:SetScript("OnValueChanged", function(control, value)
        value = math.floor(value + 0.5); BCS.charDB.backgroundOpacity = value / 100
        _G[control:GetName() .. "Text"]:SetText("Opacity: " .. value .. "%"); BCS:Refresh()
    end)
    _G[opacity:GetName() .. "Low"]:SetText("20"); _G[opacity:GetName() .. "High"]:SetText("100")
    _G[opacity:GetName() .. "Text"]:SetText("Opacity: " .. math.floor(opacity:GetValue() + 0.5) .. "%")
    self.controls.backgroundOpacity = opacity
    self:AddColor("Misc Text", "textColor", 22, -576)
    self:AddColor("Accent", "accentColor", 190, -576)
    self:AddColor("Panel Background", "backgroundColor", 358, -576)
    self:AddColor("Border", "borderColor", 526, -576)
    local reset = CreateFrame("Button", nil, self.frame, "BackdropTemplate")
    reset:SetPoint("TOP", 0, -624); reset:SetSize(220, 28); SkinControl(reset)
    reset.text = reset:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    reset.text:SetPoint("CENTER"); reset.text:SetText("Reset window positions")
    reset:SetScript("OnClick", function()
        BCS.charDB.characterFramePosition, BCS.charDB.settingsPosition = nil, nil
        CharacterFrame:SetUserPlaced(false); CharacterFrame:ClearAllPoints(); CharacterFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 16, -116)
        frame:ClearAllPoints(); frame:SetPoint("TOPLEFT", CharacterFrame, "TOPRIGHT", 8, 0)
        BCS.modules.CharacterFrame:Apply()
    end)

    -- Attributes page
    self.frame = CreatePage("attributes", 500)
    self:AddLabel("Stats sections", 18, -18, "GameFontNormal")
    self:AddStatCheckbox("General", "general", -42, 18)
    self:AddStatCheckbox("Attributes", "attributes", -42, 190)
    self:AddStatCheckbox("Secondary", "secondary", -42, 362)
    self:AddStatCheckbox("Attack", "attack", -70, 18)
    self:AddStatCheckbox("Defense", "defense", -70, 190)
    local statsHint = self:AddLabel("Drag headings in the stats panel to reorder them; click a heading to collapse it.", 22, -102)
    statsHint:SetTextColor(0.68, 0.68, 0.72, 1)
    self:AddDivider(-128)

    self:AddLabel("Heading appearance", 18, -144, "GameFontNormal")
    self:CreateFontPicker(-168, "attributesHeaderFont", "Font face")
    self:AddSlider("Font size", "attributesHeaderSize", -210, 9, 28)
    self:AddColor("Heading color", "attributesHeaderColor", 22, -250)
    self:AddDivider(-290)

    self:AddLabel("Attribute appearance", 18, -306, "GameFontNormal")
    self:CreateFontPicker(-330, "attributesBodyFont", "Font face")
    self:AddSlider("Font size", "attributesBodySize", -372, 8, 24)
    self:AddColor("Attribute color", "attributesBodyColor", 22, -412)
    self:AddDivider(-452)

    -- Reputation and Currency page
    self.frame = CreatePage("reputation", 500)
    self:AddLabel("Reputation and Currency", 18, -18, "GameFontNormal")
    self:AddSlider("Heading font size", "reputationCurrencyHeaderSize", -46, 9, 28)
    local reputationHint = self:AddLabel("Controls category headings in both the Reputation and Currency lists.", 22, -82)
    reputationHint:SetTextColor(0.68, 0.68, 0.72, 1)
    self:AddDivider(-108)

    CharacterFrame:HookScript("OnHide", function()
        frame:Hide()
        for _, popup in pairs(self.fontPopups or {}) do popup:Hide() end
        if ColorPickerFrame then ColorPickerFrame:Hide() end
    end)
    frame:HookScript("OnShow", function()
        if BCS.db.settingsWindowSnapped and not frame._bcsSlidingOpen then SnapSettings(frame) end
        self:ShowPage(self.currentPage or "character")
    end)
    frame:HookScript("OnHide", function()
        for _, popup in pairs(self.fontPopups or {}) do popup:Hide() end
        if ColorPickerFrame then ColorPickerFrame:Hide() end
        local animation = self.slideAnimation
        if animation and animation:IsPlaying() then animation:Stop() end
        local closeAnimation = self.slideCloseAnimation
        if closeAnimation and closeAnimation:IsPlaying() then closeAnimation:Stop() end
        if self.slideFinalAnchor then
            local anchor = self.slideFinalAnchor
            frame:ClearAllPoints(); frame:SetPoint(anchor.point, anchor.relativeTo, anchor.relativePoint, anchor.x, anchor.y)
            self.slideFinalAnchor = nil
        end
        if self.slideCloseAnchor then
            local anchor = self.slideCloseAnchor
            frame:ClearAllPoints(); frame:SetPoint(anchor.point, anchor.relativeTo, anchor.relativePoint, anchor.x, anchor.y)
            self.slideCloseAnchor = nil
        end
        frame._bcsSlidingOpen = nil
        frame._bcsSlidingClosed = nil
        frame:SetAlpha(1); frame:SetFrameStrata("DIALOG")
    end)
    self.frame = frame
    self:ShowPage("character")
end

function M:ShowAnimated()
    local frame = self.frame
    if not frame then return end
    if self.slideAnimation and self.slideAnimation:IsPlaying() then self.slideAnimation:Stop() end
    if self.slideCloseAnimation and self.slideCloseAnimation:IsPlaying() then self.slideCloseAnimation:Stop() end
    if self.slideCloseAnchor then
        local anchor = self.slideCloseAnchor
        frame:ClearAllPoints(); frame:SetPoint(anchor.point, anchor.relativeTo, anchor.relativePoint, anchor.x, anchor.y)
        self.slideCloseAnchor = nil
    end
    frame._bcsSlidingClosed = nil
    if not BCS.db.settingsWindowSnapped then
        frame:SetAlpha(1); frame:SetFrameStrata("DIALOG"); frame:Show()
        return
    end
    SnapSettings(frame)

    local point, relativeTo, relativePoint, x, y = frame:GetPoint(1)
    if not point then return frame:Show() end
    relativeTo = relativeTo or UIParent
    x, y = x or 0, y or 0
    self.slideFinalAnchor = { point = point, relativeTo = relativeTo, relativePoint = relativePoint or point, x = x, y = y }

    local distance = frame:GetWidth()
    frame._bcsSlidingOpen = true
    frame:ClearAllPoints(); frame:SetPoint(point, relativeTo, relativePoint or point, x - distance, y)
    frame:SetFrameStrata("LOW")
    frame:SetAlpha(0); frame:Show()

    local animation = self.slideAnimation
    if not animation then
        animation = frame:CreateAnimationGroup()
        animation.move = animation:CreateAnimation("Translation")
        animation.move:SetOrder(1); animation.move:SetSmoothing("OUT")
        animation.fade = animation:CreateAnimation("Alpha")
        animation.fade:SetOrder(1); animation.fade:SetFromAlpha(0); animation.fade:SetToAlpha(1)
        animation:SetScript("OnFinished", function()
            local anchor = self.slideFinalAnchor
            if anchor then
                frame:ClearAllPoints(); frame:SetPoint(anchor.point, anchor.relativeTo, anchor.relativePoint, anchor.x, anchor.y)
                self.slideFinalAnchor = nil
            end
            frame._bcsSlidingOpen = nil
            frame:SetAlpha(1); frame:SetFrameStrata("DIALOG")
        end)
        self.slideAnimation = animation
    end
    animation.move:SetOffset(distance, 0); animation.move:SetDuration(0.26); animation.fade:SetDuration(0.20)
    animation:Play()
end

function M:HideAnimated()
    local frame = self.frame
    if not frame or not frame:IsShown() then return end
    if not BCS.db.settingsWindowSnapped then frame:Hide(); return end
    if self.slideCloseAnimation and self.slideCloseAnimation:IsPlaying() then return end

    if self.slideAnimation and self.slideAnimation:IsPlaying() then self.slideAnimation:Stop() end
    if self.slideFinalAnchor then
        local anchor = self.slideFinalAnchor
        frame:ClearAllPoints(); frame:SetPoint(anchor.point, anchor.relativeTo, anchor.relativePoint, anchor.x, anchor.y)
        self.slideFinalAnchor = nil
    end
    frame._bcsSlidingOpen = nil
    frame:SetAlpha(1); frame:SetFrameStrata("LOW")

    local point, relativeTo, relativePoint, x, y = frame:GetPoint(1)
    if not point then frame:Hide(); return end
    self.slideCloseAnchor = { point = point, relativeTo = relativeTo or UIParent, relativePoint = relativePoint or point, x = x or 0, y = y or 0 }
    frame._bcsSlidingClosed = true

    local animation = self.slideCloseAnimation
    if not animation then
        animation = frame:CreateAnimationGroup()
        animation.move = animation:CreateAnimation("Translation")
        animation.move:SetOrder(1); animation.move:SetSmoothing("IN")
        animation.fade = animation:CreateAnimation("Alpha")
        animation.fade:SetOrder(1); animation.fade:SetFromAlpha(1); animation.fade:SetToAlpha(0)
        animation:SetScript("OnFinished", function()
            local anchor = self.slideCloseAnchor
            self.slideCloseAnchor = nil
            frame._bcsSlidingClosed = nil
            frame:SetAlpha(1); frame:SetFrameStrata("DIALOG")
            frame:Hide()
            if anchor then
                frame:ClearAllPoints(); frame:SetPoint(anchor.point, anchor.relativeTo, anchor.relativePoint, anchor.x, anchor.y)
            end
        end)
        self.slideCloseAnimation = animation
    end
    animation.move:SetOffset(-frame:GetWidth(), 0); animation.move:SetDuration(0.22); animation.fade:SetDuration(0.18)
    animation:Play()
end

function M:Refresh()
    if not self.frame then return end
    self.refreshing = true
    local bg, border = BCS.charDB.backgroundColor, BCS.charDB.borderColor
    if BCS.db.settingsWindowSnapped then SnapSettings(self.frame) end
    self.frame:SetBackdropColor(bg[1], bg[2], bg[3], 0.98 * (bg[4] or 1))
    self.frame:SetBackdropBorderColor(border[1], border[2], border[3], border[4] or 1)
    local accent = BCS.charDB.accentColor
    for _, divider in ipairs(self.dividers or {}) do divider:SetColorTexture(accent[1], accent[2], accent[3], 0.38) end
    for key, button in pairs(self.fontButtons or {}) do button.text:SetText(self:CurrentFontName(key)) end
    for _, key in ipairs({ "equipmentTopPadding", "equipmentBottomPadding", "gearTooltipScale", "characterNameSize", "gearNameSize", "guildSize",
        "attributesHeaderSize", "attributesBodySize", "reputationCurrencyHeaderSize", "slotLabelSize" }) do
        if self.controls[key] then self.controls[key]:SetValue(SliderTable(key)[key] or SliderDefault(key)) end
    end
    for _, key in ipairs({ "textColor", "accentColor", "backgroundColor", "borderColor", "attributesHeaderColor", "attributesBodyColor" }) do
        local control, color = self.controls[key], BCS.charDB[key]
        if control and control.swatch and color then control.swatch:SetColorTexture(color[1], color[2], color[3], color[4] or 1) end
    end
    self:ShowPage(self.currentPage or "character", true)
    self.refreshing = false
end

function M:Toggle()
    if not self.frame then return end
    local opening = not self.frame:IsShown()
    if opening then
        local sidePanels = BCS.modules.SidePanels
        if sidePanels and sidePanels.HideAll then sidePanels:HideAll() end
        self:Refresh()
        self:ShowAnimated()
    else
        self:HideAnimated()
    end
end

function M:Initialize()
    BCS:WhenCharacterUIReady(function()
        self:CreatePanel()
        BCS.ToggleSettings = function() self:Toggle() end
    end)
end
