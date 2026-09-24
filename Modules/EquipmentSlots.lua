local _, BCS = ...
local M = {
    slots = {
        CharacterHeadSlot = 1, CharacterNeckSlot = 2, CharacterShoulderSlot = 3, CharacterBackSlot = 15,
        CharacterChestSlot = 5, CharacterShirtSlot = 4, CharacterTabardSlot = 19, CharacterWristSlot = 9,
        CharacterHandsSlot = 10, CharacterWaistSlot = 6, CharacterLegsSlot = 7, CharacterFeetSlot = 8,
        CharacterFinger0Slot = 11, CharacterFinger1Slot = 12, CharacterTrinket0Slot = 13,
        CharacterTrinket1Slot = 14, CharacterMainHandSlot = 16, CharacterSecondaryHandSlot = 17,
    },
    rightSide = { CharacterHandsSlot = true, CharacterWaistSlot = true, CharacterLegsSlot = true,
        CharacterFeetSlot = true, CharacterFinger0Slot = true, CharacterFinger1Slot = true,
        CharacterTrinket0Slot = true, CharacterTrinket1Slot = true, CharacterMainHandSlot = true },
    enchantSlots = { [1] = true, [3] = true, [5] = true, [7] = true, [8] = true,
        [11] = true, [12] = true, [16] = true, [17] = true },
}
BCS:RegisterModule("EquipmentSlots", M)

local UPGRADE_TRACK_COLORS = {
    adventurer = "ffd6c7a1", -- Parchment
    veteran = "ffe58b72",    -- Burnished Coral
    champion = "ffa7c66b",   -- Lichen
    hero = "ff6fb6b2",       -- Sea Glass
    myth = "ffb58bc8",       -- Wisteria
}

local function CleanUpgradeTrack(track)
    if not track then return end
    -- The tooltip commonly supplies "Upgrade Level: Veteran". Keep only the
    -- actual track name so the equipment line remains compact.
    track = track:match("([^:]+)$") or track
    return track:match("^%s*(.-)%s*$")
end

local function ColorUpgrade(upgrade)
    if not BCS.charDB.gearUpgradeTrackColorsEnabled then return upgrade end
    local track = upgrade and upgrade:match("^%s*(%S+)")
    local color = track and UPGRADE_TRACK_COLORS[track:lower()]
    return color and ("|c" .. color .. upgrade .. "|r") or upgrade
end

local function ScanTooltip(slotID)
    local enchant, upgrade
    local info = C_TooltipInfo and C_TooltipInfo.GetInventoryItem and C_TooltipInfo.GetInventoryItem("player", slotID)
    for _, line in ipairs(info and info.lines or {}) do
        local text = line.leftText
        if text then
            if not enchant and ENCHANTED_TOOLTIP_LINE then
                local pattern = ENCHANTED_TOOLTIP_LINE:gsub("([%(%)%.%+%-%*%?%[%]%^%$%%])", "%%%1"):gsub("%%%%s", "(.+)")
                enchant = text:match(pattern)
            end
            if not upgrade then
                local track, current, maximum = text:match("^(.+)%s+(%d+)%s*/%s*(%d+)$")
                local durabilityWord = (DURABILITY or "Durability"):lower()
                local isDurability = track and track:lower():find(durabilityWord, 1, true)
                if track and current and maximum and not isDurability then
                    track = CleanUpgradeTrack(track)
                    upgrade = track .. " " .. current .. "/" .. maximum
                end
            end
        end
    end
    return enchant, upgrade
end

local function ItemEnchantID(link)
    return tonumber(link and link:match("item:%d+:(%d*)")) or 0
end

local function GetSocketStatus(link, slotID)
    local socketCount = 0
    if C_Item and C_Item.GetItemNumSockets then
        local ok, count = pcall(C_Item.GetItemNumSockets, link)
        if ok then socketCount = tonumber(count) or 0 end
        if socketCount == 0 and ItemLocation and ItemLocation.CreateFromEquipmentSlot then
            local location = ItemLocation:CreateFromEquipmentSlot(slotID)
            if location and location:IsValid() then
                ok, count = pcall(C_Item.GetItemNumSockets, location)
                if ok then socketCount = tonumber(count) or 0 end
            end
        end
    end

    local filled = 0
    for index = 1, math.max(socketCount, 6) do
        local _, gemLink = C_Item.GetItemGem(link, index)
        if gemLink then filled = filled + 1 end
    end

    if socketCount == 0 then
        local empty = 0
        for key, count in pairs((GetItemStats and GetItemStats(link)) or {}) do
            if type(key) == "string" and key:find("EMPTY_SOCKET_", 1, true) then
                empty = empty + (tonumber(count) or 1)
            end
        end
        socketCount = filled + empty
    end
    return socketCount, filled
end

local function GemDisplay(link, socketCount)
    local gems = {}
    for index = 1, socketCount do
        local gemName, gemLink = C_Item.GetItemGem(link, index)
        if gemLink then
            local itemID = C_Item.GetItemInfoInstant(gemLink)
            local icon = itemID and C_Item.GetItemIconByID(itemID)
            local parts = {}
            if BCS.charDB.gemIconEnabled and icon then parts[#parts + 1] = "|T" .. icon .. ":10:10:0:0|t" end
            if BCS.charDB.gemNameEnabled then parts[#parts + 1] = gemName or "Gem" end
            if #parts > 0 then gems[#gems + 1] = table.concat(parts, " ") end
        else
            local parts = {}
            if BCS.charDB.gemIconEnabled then parts[#parts + 1] = "|TInterface\\ItemSocketingFrame\\UI-EmptySocket-Prismatic:10:10:0:0|t" end
            if BCS.charDB.gemNameEnabled then parts[#parts + 1] = "Missing Gem" end
            if #parts > 0 then gems[#gems + 1] = table.concat(parts, " ") end
        end
    end
    return table.concat(gems, "  ")
end

local function CleanEnchantName(enchant)
    if not enchant then return end
    local prefix, name = enchant:match("^(.-)%s+%-%s+(.+)$")
    if prefix and prefix:lower():find("enchant", 1, true) then return name end
    return enchant
end

local function AlwaysHide(region)
    if not region or not region.Hide then return end
    region:Hide()
    if not region._bcsAlwaysHidden then
        region._bcsAlwaysHidden = true
        hooksecurefunc(region, "Show", function(current)
            current:Hide()
        end)
    end
end

local function HideForeignGearDetails(button)
    if not button then return end
    AlwaysHide(button.iLvlText)
    AlwaysHide(button.enchantText)
    for index = 1, 10 do
        AlwaysHide(button["textureSlot" .. index])
        AlwaysHide(button["textureSlotBackdrop" .. index])
    end
end

function M:CreateLabels(button, rightSide)
    if button._bcsDetails then return button._bcsDetails end
    local details = {}
    for _, key in ipairs({ "name", "level", "gem", "enchant" }) do
        local label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        label:SetWidth(235); label:SetWordWrap(false)
        label:SetJustifyH(rightSide and "RIGHT" or "LEFT")
        details[key] = label
    end
    local anchor, relative, offset = rightSide and "RIGHT" or "LEFT", rightSide and "LEFT" or "RIGHT", rightSide and -8 or 8
    details.name:SetPoint(anchor, button, relative, offset, 18)
    details.level:SetPoint(anchor, button, relative, offset, 6)
    details.gem:SetPoint(anchor, button, relative, offset, -6)
    details.enchant:SetPoint(anchor, button, relative, offset, -18)
    button._bcsDetails = details
    return details
end

function M:Update(button, slotID, rightSide)
    if not button then return end
    if BCS.modules.Theme then BCS.modules.Theme:SkinSlot(button, slotID) end
    HideForeignGearDetails(button)
    local details = self:CreateLabels(button, rightSide)
    local shown = BCS.charDB.equipmentLabelsEnabled
    for _, label in pairs(details) do label:SetShown(shown) end
    if not shown then return end

    local link = GetInventoryItemLink("player", slotID)
    if not link then
        details.name:SetText(""); details.level:SetText(""); details.gem:SetText(""); details.enchant:SetText("")
        return
    end

    local itemName, _, quality, baseLevel, _, _, _, _, equipLocation = C_Item.GetItemInfo(link)
    local level = C_Item.GetDetailedItemLevelInfo(link) or baseLevel
    local enchant, upgrade = ScanTooltip(slotID)
    enchant = CleanEnchantName(enchant)
    local currentDurability, maximumDurability = GetInventoryItemDurability(slotID)
    local durability
    if currentDurability and maximumDurability and maximumDurability > 0 and currentDurability < maximumDurability then
        durability = (DURABILITY or "Durability") .. " " .. currentDurability .. "/" .. maximumDurability
    end
    local color = quality and select(4, C_Item.GetItemQualityColor(quality)) or "ffffffff"
    BCS.modules.Fonts:Apply(details.name, "gearNameSize")
    BCS.modules.Fonts:Apply(details.level, "slotLabelSize")
    BCS.modules.Fonts:Apply(details.gem, "slotLabelSize")
    BCS.modules.Fonts:Apply(details.enchant, "slotLabelSize")
    details.name:SetText(BCS.charDB.gearItemNameEnabled and itemName and ("|c" .. color .. itemName .. "|r") or "")
    local levelParts = {}
    if durability then levelParts[#levelParts + 1] = durability end
    local upgradeCurrent, upgradeMaximum
    if upgrade then
        upgradeCurrent, upgradeMaximum = upgrade:match("(%d+)%s*/%s*(%d+)$")
    end
    local atMaxUpgrade = upgradeCurrent ~= nil and tonumber(upgradeCurrent) == tonumber(upgradeMaximum)
    if BCS.charDB.gearUpgradeLevelEnabled and upgrade and not (BCS.charDB.gearHideMaxUpgrade and atMaxUpgrade) then
        levelParts[#levelParts + 1] = ColorUpgrade(upgrade)
    end
    if level then levelParts[#levelParts + 1] = tostring(level) end
    details.level:SetText(table.concat(levelParts, "  "))

    local socketCount, filledSockets = GetSocketStatus(link, slotID)
    if (BCS.charDB.gemNameEnabled or BCS.charDB.gemIconEnabled) and socketCount > 0 then
        local missingSockets = math.max(0, socketCount - filledSockets)
        if missingSockets > 0 then
            details.gem:SetTextColor(1, 0.15, 0.15, 1)
            details.gem:SetText(GemDisplay(link, socketCount))
        else
            details.gem:SetTextColor(0.16, 0.98, 0.71, 1)
            details.gem:SetText(GemDisplay(link, socketCount))
        end
    else
        details.gem:SetText("")
    end

    local needsEnchant = self.enchantSlots[slotID]
    if slotID == 17 and equipLocation and not equipLocation:find("WEAPON") then needsEnchant = false end
    if BCS.charDB.enchantEnabled and enchant and enchant ~= "" then
        details.enchant:SetTextColor(0.16, 0.98, 0.71, 1); details.enchant:SetText(enchant)
    elseif BCS.charDB.enchantEnabled and needsEnchant and ItemEnchantID(link) == 0 then
        details.enchant:SetTextColor(1, 0.15, 0.15, 1); details.enchant:SetText("<Enchant: Missing>")
    else
        details.enchant:SetText("")
    end
end

function M:Refresh()
    for name, slotID in pairs(self.slots) do self:Update(_G[name], slotID, self.rightSide[name]) end
end

function M:ScheduleRefresh(delay)
    if self.refreshTimer then return end
    self.refreshTimer = C_Timer.NewTimer(delay or 0, function()
        self.refreshTimer = nil
        if CharacterFrame and CharacterFrame:IsShown() then self:Refresh() end
    end)
end

function M:Initialize()
    BCS:WhenCharacterUIReady(function()
        self:Refresh()
        if CharacterFrame then
            CharacterFrame:HookScript("OnShow", function() self:ScheduleRefresh(0) end)
        end
        local events = CreateFrame("Frame")
        for _, event in ipairs({ "PLAYER_EQUIPMENT_CHANGED", "UNIT_INVENTORY_CHANGED", "GET_ITEM_INFO_RECEIVED" }) do events:RegisterEvent(event) end
        events:SetScript("OnEvent", function(_, event, unit)
            if not CharacterFrame:IsShown() then return end
            if event ~= "UNIT_INVENTORY_CHANGED" or unit == "player" then self:ScheduleRefresh(0.1) end
        end)
        self.events = events
    end)
end
