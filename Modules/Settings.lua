local ADDON_NAME, BCS = ...
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

local function AttachSettings(frame)
    frame:SetClampedToScreen(false)
    frame:SetScale(CharacterFrame:GetScale())
    frame:SetHeight(CharacterFrame:GetHeight())
    frame:ClearAllPoints(); frame:SetPoint("TOPLEFT", CharacterFrame, "TOPRIGHT", 8, 0)
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
    if thumb then
        local r, g, b = BCS:GetAccentColor()
        thumb:SetTexture("Interface\\Buttons\\WHITE8X8"); thumb:SetColorTexture(r, g, b, 0.9); thumb:SetWidth(8)
        M.accentTextures = M.accentTextures or {}; M.accentTextures[#M.accentTextures + 1] = { texture = thumb, alpha = 0.9 }
    end
    for _, child in ipairs({ bar:GetChildren() }) do
        if child:IsObjectType("Button") then
            child:SetAlpha(0)
            child:EnableMouse(false)
            child:Hide()
        end
    end
end

local function SkinControl(frame)
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    frame:SetBackdropColor(0.025, 0.025, 0.035, 0.98)
    local r, g, b = BCS:GetAccentColor()
    frame:SetBackdropBorderColor(r, g, b, 0.7)
    M.accentControls = M.accentControls or {}; M.accentControls[#M.accentControls + 1] = frame
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

function M:AddMinimapCheckbox(y, x)
    local box = CreateFrame("CheckButton", nil, self.frame, "UICheckButtonTemplate")
    box:SetPoint("TOPLEFT", x or 18, y); box:SetSize(22, 22)
    box.Text:SetText("Show minimap button"); box.Text:SetTextColor(0.92, 0.92, 0.92)
    box:SetChecked(BCS.db.showMinimapButton)
    box:SetScript("OnClick", function(button) BCS:SetMinimapButtonShown(button:GetChecked()) end)
    self.controls.showMinimapButton = box
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
        if C_AddOns and C_AddOns.LoadAddOn then C_AddOns.LoadAddOn("Blizzard_ColorPickerFrame") end
    end
    if not ColorPickerFrame or not ColorPickerFrame.SetupColorPickerAndShow then return end
    local original = { unpack(BCS.charDB[key]) }
    local function Changed()
        local r, g, b = ColorPickerFrame:GetColorRGB()
        local a = ColorPickerFrame:GetColorAlpha() or original[4] or 1
        self:SetEditedColor({ r, g, b, a })
    end
    local default = BCS.characterDefaults[key]
    local defaultButton = _G.ColorPPDefault
    if defaultButton and default then
        defaultButton.colors = {
            r = default[1], g = default[2], b = default[3], a = default[4] or 1,
        }
    end
    ColorPickerFrame:SetupColorPickerAndShow({
        r = original[1], g = original[2], b = original[3], opacity = original[4] or 1, hasOpacity = true,
        swatchFunc = Changed, opacityFunc = Changed,
        cancelFunc = function() self:SetEditedColor(original) end,
    })
end

function M:AddColor(label, key, x, y, width)
    local button = CreateFrame("Button", nil, self.frame, "BackdropTemplate")
    button:SetPoint("TOPLEFT", x, y); button:SetSize(width or 150, 30); SkinControl(button)
    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    button.text:SetPoint("LEFT", 32, 0); button.text:SetPoint("RIGHT", -10, 0); button.text:SetJustifyH("LEFT"); button.text:SetText(label)
    button.swatch = button:CreateTexture(nil, "ARTWORK"); button.swatch:SetSize(17, 17); button.swatch:SetPoint("LEFT", 6, 0)
    local function RefreshSwatch()
        local color = BCS.charDB[key]; button.swatch:SetColorTexture(color[1], color[2], color[3], 1)
    end
    button:SetScript("OnClick", function()
        self:OpenColorEditor(key)
    end)
    RefreshSwatch(); self.controls[key] = button
end

function M:LayoutColorRow(keys, y, gap)
    gap = gap or 12
    local total = gap * (#keys - 1)
    for _, key in ipairs(keys) do
        local button = self.controls[key]
        local width = math.max(112, math.ceil(button.text:GetStringWidth()) + 58)
        button:SetWidth(width); total = total + width
    end
    local x = math.floor((self.frame:GetWidth() - total) * 0.5)
    for _, key in ipairs(keys) do
        local button = self.controls[key]
        button:ClearAllPoints(); button:SetPoint("TOPLEFT", self.frame, "TOPLEFT", x, y)
        x = x + button:GetWidth() + gap
    end
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
    button.arrow = button:CreateTexture(nil, "OVERLAY")
    button.arrow:SetPoint("RIGHT", -8, 0); button.arrow:SetSize(12, 12)
    button.arrow:SetAtlas("dropdown-hover-arrow")
    button.arrow:SetVertexColor(0.92, 0.92, 0.92, 1)

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
        entry:SetHighlightTexture("Interface\\Buttons\\WHITE8X8")
        local highlight = entry:GetHighlightTexture()
        local r, g, b = BCS:GetAccentColor(); highlight:SetVertexColor(r, g, b, 0.18)
        self.accentTextures = self.accentTextures or {}; self.accentTextures[#self.accentTextures + 1] = { texture = highlight, alpha = 0.18, vertex = true }
        entry:SetScript("OnClick", function()
            SettingTable()[key] = selected.path
            button.text:SetText(selected.name)
            popup:Hide(); BCS:Refresh()
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
    if self.panelReady or self.panelBuilding then return end
    self.panelBuilding = true
    self.panelReady = false
    local frame = CreateFrame("Frame", "BoojieCharacterSheetSettingsFrame", UIParent, "BackdropTemplate")
    frame:SetSize(720, CharacterFrame:GetHeight())
    AttachSettings(frame)
    frame:SetFrameStrata("DIALOG"); frame:SetFrameLevel(500); SkinControl(frame); frame:Hide()
    frame:SetMovable(false); frame:EnableMouse(true)
    self.frame, self.window = frame, frame
    local version = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version") or ""
    local title = self:AddLabel("Boojie Character Sheet v" .. version, 18, -16, "GameFontNormalLarge")
    title:SetTextColor(1, 0.553, 0.631)
    local accentR, accentG, accentB = BCS:GetAccentColor()
    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    frame.closeButton = close
    close:SetPoint("TOPRIGHT", -4, -4); close:SetFrameLevel(frame:GetFrameLevel() + 5)
    BCS.modules.Theme:SkinCloseButton(close)
    close:SetScript("OnClick", function()
        self:Close()
        if ColorPickerFrame then ColorPickerFrame:Hide() end
    end)
    local line = frame:CreateTexture(nil, "ARTWORK"); line:SetColorTexture(accentR, accentG, accentB, 0.5)
    line:SetPoint("TOPLEFT", 15, -44); line:SetPoint("TOPRIGHT", -15, -44); line:SetHeight(1)
    self.dividers = self.dividers or {}; self.dividers[#self.dividers + 1] = line

    self.pages, self.pageButtons = {}, {}
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
    local navigationLine = frame:CreateTexture(nil, "ARTWORK"); navigationLine:SetColorTexture(accentR, accentG, accentB, 0.35)
    navigationLine:SetPoint("TOPLEFT", 15, -88); navigationLine:SetPoint("TOPRIGHT", -15, -88); navigationLine:SetHeight(1)
    self.dividers[#self.dividers + 1] = navigationLine

    -- Character Sheet page
    self.frame = CreatePage("character", 620)
    self:AddLabel("Live appearance", 18, -18, "GameFontNormal")
    self:AddCheckbox("Show gear labels and item levels", "equipmentLabelsEnabled", -40, false, 18)
    self:AddCheckbox("Show live character view", "liveCharacterViewEnabled", -40, false, 280)
    self:AddMinimapCheckbox(-40, 500)
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
    self:AddColor("Misc Text", "textColor", 22, -530)
    self:AddColor("Accent", "accentColor", 190, -530)
    self:AddColor("Character Sheet Background", "characterSheetBackgroundColor", 342, -530, 176)
    self:AddColor("Border", "borderColor", 526, -530)
    self:LayoutColorRow({ "textColor", "accentColor", "characterSheetBackgroundColor", "borderColor" }, -530)

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
    self:AddColor("Attributes Background", "attributesBackgroundColor", 190, -412, 180)
    self:AddDivider(-452)

    -- Reputation and Currency page
    self.frame = CreatePage("reputation", 500)
    self:AddLabel("Reputation and Currency", 18, -18, "GameFontNormal")
    self:AddSlider("Heading font size", "reputationCurrencyHeaderSize", -46, 9, 28)
    local reputationHint = self:AddLabel("Controls category headings in both the Reputation and Currency lists.", 22, -82)
    reputationHint:SetTextColor(0.68, 0.68, 0.72, 1)
    self:AddDivider(-108)

    self:AddLabel("Bar appearance", 18, -124, "GameFontNormal")
    self:AddCheckbox("Use ElvUI General texture for reputation bars", "useElvUIReputationTexture", -148, false, 18)
    local textureHint = self:AddLabel("Uses Blizzard's texture when ElvUI is unavailable.", 22, -180)
    textureHint:SetTextColor(0.68, 0.68, 0.72, 1)
    self:AddDivider(-206)

    CharacterFrame:HookScript("OnHide", function() frame:Hide() end)
    frame:HookScript("OnShow", function()
        AttachSettings(frame)
        self:ShowPage(self.currentPage or "character")
    end)
    frame:HookScript("OnHide", function()
        for _, popup in pairs(self.fontPopups or {}) do popup:Hide() end
        if ColorPickerFrame then ColorPickerFrame:Hide() end
    end)
    self.frame = frame
    self:ShowPage("character")
    self.panelReady = true
    self.panelBuilding = false
end

function M:Open()
    if not self.panelReady then return end
    AttachSettings(self.window)
    self.window:Show()
end

function M:Close()
    if self.panelReady then self.window:Hide() end
end

function M:Refresh()
    if not self.panelReady then return end
    self.refreshing = true
    local border = BCS.charDB.borderColor
    AttachSettings(self.window)
    self.window:SetBackdropColor(0, 0, 0, 1)
    self.window:SetBackdropBorderColor(border[1], border[2], border[3], border[4] or 1)
    local accent = BCS.charDB.accentColor
    for _, control in ipairs(self.accentControls or {}) do control:SetBackdropBorderColor(accent[1], accent[2], accent[3], 0.7) end
    for _, region in ipairs(self.accentTextures or {}) do
        if region.vertex then region.texture:SetVertexColor(accent[1], accent[2], accent[3], region.alpha)
        else region.texture:SetColorTexture(accent[1], accent[2], accent[3], region.alpha) end
    end
    for _, divider in ipairs(self.dividers or {}) do divider:SetColorTexture(accent[1], accent[2], accent[3], 0.38) end
    if self.controls.showMinimapButton then self.controls.showMinimapButton:SetChecked(BCS.db.showMinimapButton) end
    for key, button in pairs(self.fontButtons or {}) do button.text:SetText(self:CurrentFontName(key)) end
    for _, key in ipairs({ "equipmentTopPadding", "equipmentBottomPadding", "gearTooltipScale", "characterNameSize", "gearNameSize", "guildSize",
        "attributesHeaderSize", "attributesBodySize", "reputationCurrencyHeaderSize", "slotLabelSize" }) do
        if self.controls[key] then self.controls[key]:SetValue(SliderTable(key)[key] or SliderDefault(key)) end
    end
    for _, key in ipairs({ "textColor", "accentColor", "characterSheetBackgroundColor", "attributesBackgroundColor", "borderColor", "attributesHeaderColor", "attributesBodyColor" }) do
        local control, color = self.controls[key], BCS.charDB[key]
        if control and control.swatch and color then control.swatch:SetColorTexture(color[1], color[2], color[3], color[4] or 1) end
    end
    self:ShowPage(self.currentPage or "character", true)
    self.refreshing = false
end

function M:Toggle()
    if not self.panelReady then return end
    local opening = not self.window:IsShown()
    if opening then
        local sidePanels = BCS.modules.SidePanels
        if sidePanels and sidePanels.HideAll then sidePanels:HideAll() end
        self:Refresh()
        self:Open()
    else
        self:Close()
    end
end

function M:Initialize()
    BCS:WhenCharacterUIReady(function()
        self:CreatePanel()
        if self.panelReady then BCS.ToggleSettings = function() self:Toggle() end end
    end)
end
