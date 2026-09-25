local ADDON_NAME, BCS = ...
local ADDON_TITLE = "Boojie Character Sheet"
local ADDON_ICON = "Interface\\AddOns\\BoojieCharacterSheet\\BoojieCharacterSheetBCSIcon.png"
local LDB_NAME = "BoojieCharacterSheetLauncher"

_G.BoojieCharacterSheet = BCS
BCS.modules = BCS.modules or {}
BCS.characterReadyCallbacks = BCS.characterReadyCallbacks or {}

local characterLoader = CreateFrame("Frame")
characterLoader:RegisterEvent("ADDON_LOADED")
characterLoader:RegisterEvent("PLAYER_LOGIN")

function BCS:FlushCharacterUIReady()
    if not CharacterFrame then return false end
    for callback in pairs(self.characterReadyCallbacks) do
        self.characterReadyCallbacks[callback] = nil
        local ok = xpcall(callback, geterrorhandler())
        if not ok then self:Print("Character-sheet initialization failed; the full error was sent to BugGrabber.") end
    end
    return true
end

function BCS:WhenCharacterUIReady(callback)
    if type(callback) ~= "function" then return end
    self.characterReadyCallbacks[callback] = true
    self:FlushCharacterUIReady()
end

characterLoader:SetScript("OnEvent", function(_, event, addon)
    if event == "PLAYER_LOGIN" and not CharacterFrame and C_AddOns and C_AddOns.LoadAddOn then
        C_AddOns.LoadAddOn("Blizzard_CharacterUI")
    end
    if CharacterFrame or addon == "Blizzard_CharacterUI" then
        BCS:FlushCharacterUIReady()
        if CharacterFrame then
            characterLoader:UnregisterEvent("ADDON_LOADED")
            characterLoader:UnregisterEvent("PLAYER_LOGIN")
        end
    end
end)

local function Copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, child in pairs(value) do result[key] = Copy(child) end
    return result
end

local function ApplyDefaults(target, defaults)
    for key, value in pairs(defaults) do
        if target[key] == nil then target[key] = Copy(value)
        elseif type(value) == "table" and type(target[key]) == "table" then ApplyDefaults(target[key], value) end
    end
end

function BCS:RegisterModule(name, module) self.modules[name] = module end
function BCS:GetAccentColor()
    local color = self.charDB and self.charDB.accentColor or self.characterDefaults.accentColor
    return color[1], color[2], color[3], color[4] or 1
end
function BCS:AccentText(text)
    local r, g, b = self:GetAccentColor()
    return ("|cff%02x%02x%02x%s|r"):format(
        math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5), tostring(text))
end
function BCS:GetTypography(key)
    local account = self.db.typography
    local character = self.charDB.typography
    local value = account.useAccountWide and account[key] or character[key]
    if value == nil then value = self.defaults.typography[key] end
    if key == "font" then
        local sharedName = self.GetMediaName and self:GetMediaName("font")
        if sharedName and self.LSM then value = self.LSM:Fetch("font", sharedName, true) or value end
        if not value then value = self.media.defaultFont end
    end
    if key ~= "font" and key:match("Font$") and not value then value = self:GetTypography("font") end
    return value
end
function BCS:Print(message) print(self:AccentText("Boojie Character Sheet:") .. " " .. tostring(message)) end

local function ToggleCharacterSheet()
    if not CharacterFrame and C_AddOns and C_AddOns.LoadAddOn then C_AddOns.LoadAddOn("Blizzard_CharacterUI") end
    local opening = CharacterFrame and not CharacterFrame:IsShown()
    local characterModule = BCS.modules.CharacterFrame
    if opening then
        CharacterFrame:SetAlpha(0)
        if characterModule and characterModule.Apply then characterModule:Apply() end
    end
    if type(ToggleCharacter) == "function" then
        ToggleCharacter("PaperDollFrame")
    elseif CharacterFrame then
        if CharacterFrame:IsShown() then HideUIPanel(CharacterFrame)
        else
            ShowUIPanel(CharacterFrame)
            if type(CharacterFrame_ShowSubFrame) == "function" then CharacterFrame_ShowSubFrame("PaperDollFrame") end
        end
    end
    if opening then
        C_Timer.After(0.06, function()
            if characterModule and characterModule.Apply then characterModule:Apply() end
            CharacterFrame:SetAlpha(1)
        end)
    end
end

function BCS:SetMinimapButtonShown(shown)
    self.db.showMinimapButton = not not shown
    self.db.minimap.hide = not self.db.showMinimapButton
    if not self.dbIcon then return end
    if self.db.showMinimapButton then self.dbIcon:Show(LDB_NAME) else self.dbIcon:Hide(LDB_NAME) end
end

function BCS:CreateMinimapButton()
    if self.minimapButton then return end
    local libStub = _G.LibStub
    local dataBroker = libStub and libStub("LibDataBroker-1.1", true)
    local dbIcon = libStub and libStub("LibDBIcon-1.0", true)
    if not dataBroker or not dbIcon then return end
    local launcher = dataBroker:NewDataObject(LDB_NAME, {
        type = "launcher", label = ADDON_TITLE, text = ADDON_TITLE, icon = ADDON_ICON,
        OnClick = function(_, mouseButton)
            if mouseButton == "RightButton" and BCS.ToggleSettings then BCS.ToggleSettings()
            elseif mouseButton == "LeftButton" then ToggleCharacterSheet() end
        end,
        OnTooltipShow = function(tooltip)
            local r, g, b = BCS:GetAccentColor()
            tooltip:AddLine(ADDON_TITLE, r, g, b)
            tooltip:AddLine("Left-click to open the character sheet.", 1, 1, 1)
            tooltip:AddLine("Right-click to open settings.", 1, 1, 1)
        end,
    })
    self.db.minimap.hide = not self.db.showMinimapButton
    dbIcon:Register(LDB_NAME, launcher, self.db.minimap)
    self.dbIcon = dbIcon
    self.minimapButton = dbIcon:GetMinimapButton(LDB_NAME)
end

local function OpenAddonSettings()
    if not CharacterFrame or not CharacterFrame:IsShown() then ToggleCharacterSheet() end
    C_Timer.After(0.08, function()
        local settings = BCS.modules.Settings
        if settings and settings.panelReady then settings:Refresh(); settings:Open() end
    end)
end

function BCS:RegisterBlizzardSettings()
    if self.settingsCategory or not Settings or not Settings.RegisterCanvasLayoutCategory or not Settings.RegisterAddOnCategory then return end
    local panel = CreateFrame("Frame")
    local icon = panel:CreateTexture(nil, "ARTWORK")
    icon:SetSize(128, 128); icon:SetPoint("TOP", 0, -28); icon:SetTexture(ADDON_ICON)
    local version = C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version") or ""
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOP", icon, "BOTTOM", 0, -12)
    title:SetText("|cFFFF8DA1" .. ADDON_TITLE .. "|r  |cffaaaaaav" .. version .. "|r")
    local description = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    description:SetPoint("TOP", title, "BOTTOM", 0, -10)
    description:SetText("A lightweight skin and gear-status enhancement for Blizzard's character sheet.")
    local open = CreateFrame("Button", nil, panel, "BackdropTemplate")
    open:SetSize(210, 28); open:SetPoint("TOP", description, "BOTTOM", 0, -18)
    open:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    local accentR, accentG, accentB = self:GetAccentColor()
    open:SetBackdropColor(0.025, 0.025, 0.035, 0.98); open:SetBackdropBorderColor(accentR, accentG, accentB, 1)
    local openText = open:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    openText:SetPoint("CENTER"); openText:SetText("Open Boojie Character Sheet")
    open:SetScript("OnEnter", function(button) button:SetBackdropColor(0.10, 0.10, 0.12, 1) end)
    open:SetScript("OnLeave", function(button) button:SetBackdropColor(0.025, 0.025, 0.035, 0.98) end)
    open:SetScript("OnClick", OpenAddonSettings)
    local slash = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    slash:SetPoint("TOP", open, "BOTTOM", 0, -12); slash:SetText("/bcs  or  /boojiecharactersheet")
    local minimap = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    minimap:SetPoint("TOP", slash, "BOTTOM", -72, -18)
    minimap.Text:SetText("Show minimap button")
    minimap:SetScript("OnClick", function(button) BCS:SetMinimapButtonShown(button:GetChecked()) end)
    panel:SetScript("OnShow", function() minimap:SetChecked(BCS.db.showMinimapButton) end)
    local author = panel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    author:SetPoint("BOTTOM", 0, 24); author:SetText("Author: SilverRavyn")
    local category = Settings.RegisterCanvasLayoutCategory(panel, ADDON_TITLE)
    Settings.RegisterAddOnCategory(category)
    self.blizzardSettingsOpenButton = open
    self.settingsCategory = category
end
function BCS:RefreshAccentUI()
    local r, g, b = self:GetAccentColor()
    if self.blizzardSettingsOpenButton then self.blizzardSettingsOpenButton:SetBackdropBorderColor(r, g, b, 1) end
end
function BCS:Refresh()
    self:RefreshAccentUI()
    for _, module in pairs(self.modules) do if module.Refresh then module:Refresh() end end
end

function BCS:InitializeDatabase()
    BoojieCharacterSheetDB = type(BoojieCharacterSheetDB) == "table" and BoojieCharacterSheetDB or {}
    BoojieCharacterSheetCharDB = type(BoojieCharacterSheetCharDB) == "table" and BoojieCharacterSheetCharDB or {}
    BoojieCharacterSheetDB.minimap = type(BoojieCharacterSheetDB.minimap) == "table" and BoojieCharacterSheetDB.minimap or {}
    if BoojieCharacterSheetDB.minimap.minimapPos == nil then
        BoojieCharacterSheetDB.minimap.minimapPos = BoojieCharacterSheetDB.minimapAngle or self.defaults.minimap.minimapPos
    end
    BoojieCharacterSheetDB.minimapAngle = nil
    BoojieCharacterSheetDB.settingsWindowSnapped = nil
    BoojieCharacterSheetCharDB.settingsWindowSnapped = nil
    BoojieCharacterSheetCharDB.settingsPosition = nil
    for _, key in ipairs({ "titleWindowSnapped", "equipmentWindowSnapped" }) do
        BoojieCharacterSheetDB[key] = nil
        BoojieCharacterSheetCharDB[key] = nil
    end
    BoojieCharacterSheetCharDB.titleWindowPosition = nil
    BoojieCharacterSheetCharDB.equipmentWindowPosition = nil
    BoojieCharacterSheetCharDB.headerColor = nil
    BoojieCharacterSheetCharDB.sectionHeadersEnabled = nil
    BoojieCharacterSheetCharDB.infoDockPosition = nil
    BoojieCharacterSheetCharDB.restrainedTabsEnabled = nil
    BoojieCharacterSheetCharDB.backgroundOpacity = nil
    if type(BoojieCharacterSheetCharDB.backgroundColor) == "table" then
        if BoojieCharacterSheetCharDB.characterSheetBackgroundColor == nil then
            BoojieCharacterSheetCharDB.characterSheetBackgroundColor = Copy(BoojieCharacterSheetCharDB.backgroundColor)
        end
        if BoojieCharacterSheetCharDB.attributesBackgroundColor == nil then
            BoojieCharacterSheetCharDB.attributesBackgroundColor = Copy(BoojieCharacterSheetCharDB.backgroundColor)
        end
    end
    BoojieCharacterSheetCharDB.backgroundColor = nil
    for _, database in ipairs({ BoojieCharacterSheetDB, BoojieCharacterSheetCharDB }) do
        local typography = type(database.typography) == "table" and database.typography
        if typography then
            if typography.guildSize == nil and typography.headerSize ~= nil then typography.guildSize = typography.headerSize end
            if typography.gearNameSize == nil and typography.bodySize ~= nil then typography.gearNameSize = typography.bodySize end
            typography.headerSize = nil
            typography.bodySize = nil
        end
    end
    local legacyGearDetails = BoojieCharacterSheetCharDB.gearDetailsEnabled
    if legacyGearDetails == false then
        BoojieCharacterSheetCharDB.gearItemNameEnabled = false
        BoojieCharacterSheetCharDB.gemNameEnabled = false
        BoojieCharacterSheetCharDB.gemIconEnabled = false
        BoojieCharacterSheetCharDB.enchantEnabled = false
    end
    BoojieCharacterSheetCharDB.gearDetailsEnabled = nil
    BoojieCharacterSheetCharDB.infoDockEnabled = nil
    local order = BoojieCharacterSheetCharDB.statsOrder
    if type(order) == "table" and table.concat(order, ",") == "attributes,secondary,attack,defense,general" then
        BoojieCharacterSheetCharDB.statsOrder = { "general", "attributes", "secondary", "attack", "defense" }
    end
    ApplyDefaults(BoojieCharacterSheetDB, self.defaults)
    ApplyDefaults(BoojieCharacterSheetCharDB, self.characterDefaults)
    self.db, self.charDB = BoojieCharacterSheetDB, BoojieCharacterSheetCharDB
end

function BCS:Initialize()
    self:InitializeDatabase()
    self:InitializeMedia()
    for _, module in pairs(self.modules) do if module.Initialize then module:Initialize() end end
    self:CreateMinimapButton()
    self:RegisterBlizzardSettings()
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function(_, _, addon)
    if addon == ADDON_NAME then BCS:Initialize() end
end)

SLASH_BOOJIECHARACTERSHEET1 = "/bcs"
SLASH_BOOJIECHARACTERSHEET2 = "/boojiecharactersheet"
SlashCmdList.BOOJIECHARACTERSHEET = function(message)
    message = strtrim(message or ""):lower()
    if message == "debug" and BCS.Debug then BCS.Debug:Report() return end
    if BCS.ToggleSettings then BCS.ToggleSettings()
    elseif CharacterFrame then ToggleCharacter("PaperDollFrame") end
end

SLASH_BOOJIERELOAD1 = SLASH_BOOJIERELOAD1 or "/rl"
SlashCmdList.BOOJIERELOAD = SlashCmdList.BOOJIERELOAD or ReloadUI
