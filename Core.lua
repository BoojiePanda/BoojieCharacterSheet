local ADDON_NAME, BCS = ...

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
function BCS:GetTypography(key)
    local account = self.db.typography
    local character = self.charDB.typography
    local value = account.useAccountWide and account[key] or character[key]
    if value == nil then value = self.defaults.typography[key] end
    if key == "font" and not value then value = self.media.defaultFont end
    if key ~= "font" and key:match("Font$") and not value then value = self:GetTypography("font") end
    return value
end
function BCS:Print(message) print("|cFFFF8DA1Boojie Character Sheet:|r " .. tostring(message)) end

local function PositionMinimapButton(button)
    local radius = (Minimap:GetWidth() * 0.5) + 10
    local radians = math.rad(BCS.db.minimapAngle)
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", math.cos(radians) * radius, math.sin(radians) * radius)
end

local function SkinMinimapButton(button, icon)
    button:SetSize(31, 31); button:SetFrameStrata("MEDIUM"); button:SetFrameLevel(8)
    button:SetHitRectInsets(-6, -6, -6, -6)
    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetTexture(136467); background:SetSize(24, 24); background:SetPoint("CENTER")
    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture(136430); border:SetSize(50, 50); border:SetPoint("TOPLEFT")
    icon:ClearAllPoints(); icon:SetPoint("CENTER"); icon:SetSize(18, 18)
    button.background, button.border = background, border
end

local function SyncMinimapButtonPresentation(button)
    local onMinimap = button:GetParent() == Minimap
    button.background:SetShown(onMinimap)
    button.border:SetShown(onMinimap)
end

function BCS:CreateMinimapButton()
    if self.minimapButton then return end
    local button = CreateFrame("Button", "BoojieCharacterSheetMinimapButton", Minimap)
    button:SetSize(30, 30)
    PositionMinimapButton(button)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\AddOns\\BoojieCharacterSheet\\BoojieCharacterSheetIcon.png")
    icon:SetSize(18, 18); icon:SetPoint("CENTER")
    button.icon = icon
    SkinMinimapButton(button, icon)
    SyncMinimapButtonPresentation(button)
    hooksecurefunc(button, "SetParent", SyncMinimapButtonPresentation)
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    button:SetScript("OnClick", function(_, mouseButton)
        if button._bcsJustDragged then return end
        if mouseButton == "RightButton" and BCS.ToggleSettings then
            BCS.ToggleSettings()
        elseif mouseButton == "LeftButton" then
            if not CharacterFrame and C_AddOns and C_AddOns.LoadAddOn then
                C_AddOns.LoadAddOn("Blizzard_CharacterUI")
            end
            local opening = CharacterFrame and not CharacterFrame:IsShown()
            local characterModule = BCS.modules.CharacterFrame
            if opening then
                CharacterFrame:SetAlpha(0)
                if characterModule and characterModule.Apply then characterModule:Apply() end
            end
            if type(ToggleCharacter) == "function" then
                ToggleCharacter("PaperDollFrame")
            elseif CharacterFrame then
                if CharacterFrame:IsShown() then
                    HideUIPanel(CharacterFrame)
                else
                    ShowUIPanel(CharacterFrame)
                    if type(CharacterFrame_ShowSubFrame) == "function" then
                        CharacterFrame_ShowSubFrame("PaperDollFrame")
                    end
                end
            end
            if opening then
                C_Timer.After(0.06, function()
                    if characterModule and characterModule.Apply then characterModule:Apply() end
                    CharacterFrame:SetAlpha(1)
                end)
            end
        end
    end)
    button:SetScript("OnEnter", function(owner)
        local mapX = Minimap:GetCenter()
        GameTooltip:SetOwner(Minimap, mapX and mapX < (UIParent:GetWidth() * 0.5) and "ANCHOR_RIGHT" or "ANCHOR_LEFT")
        GameTooltip:AddLine("Boojie Character Sheet")
        GameTooltip:AddLine("Left-click to open the character sheet.", 1, 1, 1)
        GameTooltip:AddLine("Right-click to open settings.", 1, 1, 1)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", GameTooltip_Hide)
    button:SetScript("OnDragStart", function(current)
        current:SetScript("OnUpdate", function()
            local cursorX, cursorY = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            local centerX, centerY = Minimap:GetCenter()
            if centerX and centerY then
                BCS.db.minimapAngle = math.deg(math.atan2((cursorY / scale) - centerY, (cursorX / scale) - centerX))
                PositionMinimapButton(current)
            end
        end)
    end)
    button:SetScript("OnDragStop", function(current)
        current:SetScript("OnUpdate", nil); current._bcsJustDragged = true
        PositionMinimapButton(current)
        C_Timer.After(0, function() current._bcsJustDragged = nil end)
    end)

    local hitTarget = CreateFrame("Button", nil, UIParent)
    hitTarget:SetSize(38, 38)
    hitTarget:SetPoint("CENTER", button, "CENTER")
    local function SyncHitTarget()
        local onMinimap = button:GetParent() == Minimap
        local parent = onMinimap and UIParent or button:GetParent() or UIParent
        if hitTarget:GetParent() ~= parent then hitTarget:SetParent(parent) end
        hitTarget:SetFrameStrata(button:GetFrameStrata())
        hitTarget:SetFrameLevel(button:GetFrameLevel() + 1)
        hitTarget:SetShown(onMinimap)
        button:EnableMouse(not onMinimap)
    end
    SyncHitTarget()
    hooksecurefunc(button, "SetParent", SyncHitTarget)
    hooksecurefunc(button, "SetFrameStrata", SyncHitTarget)
    hooksecurefunc(button, "SetFrameLevel", SyncHitTarget)
    hitTarget:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    hitTarget:RegisterForDrag("LeftButton")
    hitTarget:SetScript("OnClick", function(_, mouseButton)
        local script = button:GetScript("OnClick")
        if script then script(button, mouseButton) end
    end)
    hitTarget:SetScript("OnEnter", function()
        local script = button:GetScript("OnEnter")
        if script then script(button) end
    end)
    hitTarget:SetScript("OnLeave", function()
        local script = button:GetScript("OnLeave")
        if script then script(button) end
    end)
    hitTarget:SetScript("OnDragStart", function()
        local script = button:GetScript("OnDragStart")
        if script then script(button) end
    end)
    hitTarget:SetScript("OnDragStop", function()
        local script = button:GetScript("OnDragStop")
        if script then script(button) end
    end)
    button.hitTarget = hitTarget
    self.minimapButton = button
end
function BCS:Refresh()
    for _, module in pairs(self.modules) do if module.Refresh then module:Refresh() end end
end

function BCS:InitializeDatabase()
    BoojieCharacterSheetDB = type(BoojieCharacterSheetDB) == "table" and BoojieCharacterSheetDB or {}
    BoojieCharacterSheetCharDB = type(BoojieCharacterSheetCharDB) == "table" and BoojieCharacterSheetCharDB or {}
    for _, key in ipairs({ "settingsWindowSnapped" }) do
        if BoojieCharacterSheetDB[key] == nil and BoojieCharacterSheetCharDB[key] ~= nil then
            BoojieCharacterSheetDB[key] = BoojieCharacterSheetCharDB[key]
        end
        BoojieCharacterSheetCharDB[key] = nil
    end
    for _, key in ipairs({ "titleWindowSnapped", "equipmentWindowSnapped" }) do
        BoojieCharacterSheetDB[key] = nil
        BoojieCharacterSheetCharDB[key] = nil
    end
    BoojieCharacterSheetCharDB.titleWindowPosition = nil
    BoojieCharacterSheetCharDB.equipmentWindowPosition = nil
    BoojieCharacterSheetCharDB.headerColor = nil
    BoojieCharacterSheetCharDB.sectionHeadersEnabled = nil
    BoojieCharacterSheetCharDB.infoDockPosition = nil
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
    self:DiscoverFonts()
    for _, module in pairs(self.modules) do if module.Initialize then module:Initialize() end end
    self:CreateMinimapButton()
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
