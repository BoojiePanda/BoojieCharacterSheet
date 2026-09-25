local _, BCS = ...
local M = { rows = {}, sections = {} }
BCS:RegisterModule("InfoDock", M)

local SECTION_DEFS = {
    attributes = { title = "Attributes", rows = { { "primary", "Primary" }, { "stamina", "Stamina" }, { "health", "Health" }, { "power", "Power" }, { "gcd", "GCD" } } },
    secondary = { title = "Secondary", rows = { { "haste", "Haste" }, { "mastery", "Mastery" }, { "critical", "Critical Strike" }, { "versatility", "Versatility" } } },
    attack = { title = "Attack", rows = { { "attackPower", "Attack Power" }, { "attackSpeed", "Attack Speed" }, { "spellPower", "Spell Power" } } },
    defense = { title = "Defense", rows = { { "armor", "Armor" }, { "dodge", "Dodge" }, { "parry", "Parry" }, { "block", "Block" }, { "stagger", "Stagger" } } },
    general = { title = "General", rows = { { "itemLevel", "Item Level" }, { "durability", "Durability" }, { "leech", "Leech" }, { "avoidance", "Avoidance" }, { "speed", "Speed" }, { "runSpeed", "Movement" }, { "groundMountSpeed", "Ground Mount Speed" }, { "flightSpeed", "Flight Speed" } } },
}

local STAT_HELP = {
    primary = "Your specialization's primary attribute. It increases the effectiveness of your attacks and spells.",
    stamina = "Increases your maximum health.", health = "The maximum amount of damage you can take before dying.",
    power = "Your active class resource and its current maximum.", gcd = "Your estimated global cooldown after haste.",
    haste = "Increases attack speed and the rate of many spells and periodic effects.",
    mastery = "Improves your specialization's unique Mastery effect.",
    critical = "Your chance for attacks and spells to critically strike.",
    versatility = "Increases damage and healing done and reduces damage taken.",
    attackPower = "Determines the strength of your physical attacks.",
    attackSpeed = "The time between automatic weapon attacks. Lower is faster.",
    spellPower = "Determines the strength of your damaging and healing spells.",
    armor = "Reduces physical damage taken from enemies.", dodge = "Chance to completely avoid a melee attack.",
    parry = "Chance to parry and completely avoid a melee attack.", block = "Chance to block part of an incoming melee attack with a shield.",
    stagger = "The portion of incoming damage delayed by Stagger.", itemLevel = "The average item level of your currently equipped gear.",
    durability = "The overall durability remaining on your equipped gear.", leech = "Returns a portion of your damage and healing as healing to you.",
    avoidance = "Reduces damage taken from area-of-effect attacks.", speed = "Bonus movement speed granted by the Speed tertiary stat.",
    runSpeed = "Your movement speed compared with normal running speed.",
    groundMountSpeed = "Your mounted ground speed compared with normal running speed.",
    flightSpeed = "Your mounted flight speed compared with normal running speed.",
}

local function SafeNumber(func, ...)
    if type(func) ~= "function" then return 0 end
    local ok, value = pcall(func, ...)
    return ok and tonumber(value) or 0
end

local function LowestDurability()
    local lowest
    for slot = 1, 19 do
        local current, maximum = GetInventoryItemDurability(slot)
        if current and maximum and maximum > 0 then
            local durability = floor(current / maximum * 100 + 0.5)
            if not lowest or durability < lowest then lowest = durability end
        end
    end
    return lowest
end

local function PrimaryStat()
    local bestName, bestValue = "Strength", 0
    for _, stat in ipairs({ { 1, "Strength" }, { 2, "Agility" }, { 4, "Intellect" } }) do
        local value = select(2, UnitStat("player", stat[1])) or 0
        if value > bestValue then bestName, bestValue = stat[2], value end
    end
    return bestName, bestValue
end

local function RatingPercent(percent, rating)
    return ("(%.2f%%) %s"):format(percent or 0, BreakUpLargeNumbers(rating or 0))
end

local function MovementValues()
    local ok, current, run, flight = pcall(GetUnitSpeed, "player")
    if not ok then current, run, flight = 0, 7, 0 end
    current, run, flight = tonumber(current) or 0, tonumber(run) or 7, tonumber(flight) or 0
    local mounted = type(IsMounted) == "function" and IsMounted()
    local moving = current > 0.01
    local runModified = math.abs(run - 7) > 0.01
    local tertiarySpeed = SafeNumber(GetSpeed)
    return {
        speed = ("%.2f%%"):format(tertiarySpeed),
        runSpeed = ("%.0f%%"):format(run / 7 * 100),
        groundMountSpeed = ("%.0f%%"):format(run / 7 * 100),
        flightSpeed = ("%.0f%%"):format(flight / 7 * 100),
    }, {
        speed = true,
        runSpeed = not mounted and (moving or runModified),
        groundMountSpeed = mounted and run > 7.01,
        flightSpeed = mounted and flight > 7.01,
    }
end

local function CreateDock()
    local dock = CreateFrame("Frame", "BoojieCharacterSheetInfoDock", PaperDollFrame, "BackdropTemplate")
    dock:SetSize(250, 510); dock:SetPoint("TOPRIGHT", CharacterFrame, "TOPRIGHT", -14, -82)
    dock:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    return dock
end

function M:MoveSection(sourceKey, targetKey)
    if sourceKey == targetKey then return end
    local order, sourceIndex, targetIndex = BCS.charDB.statsOrder
    for index, key in ipairs(order) do
        if key == sourceKey then sourceIndex = index end
        if key == targetKey then targetIndex = index end
    end
    if not sourceIndex or not targetIndex then return end
    table.remove(order, sourceIndex)
    table.insert(order, targetIndex, sourceKey)
    self:Layout(); self:Refresh()
end

function M:CreateSection(key)
    local definition = SECTION_DEFS[key]
    local section = CreateFrame("Frame", nil, self.frame); section:SetWidth(238)
    section.header = CreateFrame("Button", nil, section)
    section.header:SetHeight(20); section.header:SetPoint("TOPLEFT"); section.header:SetPoint("TOPRIGHT")
    section.header:RegisterForClicks("LeftButtonUp"); section.header:RegisterForDrag("LeftButton")
    section.header.text = section.header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    section.header.text:SetPoint("CENTER"); section.header.text:SetText(definition.title)
    section.header.indicator = section.header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    section.header.indicator:SetPoint("RIGHT", -5, 0)
    local line = section.header:CreateTexture(nil, "BACKGROUND")
    line:SetHeight(1); line:SetPoint("BOTTOMLEFT", 2, 1); line:SetPoint("BOTTOMRIGHT", -2, 1); section.line = line
    section.rows = {}
    for index, rowDefinition in ipairs(definition.rows) do
        local row = CreateFrame("Frame", nil, section)
        row:SetHeight(16); row:SetPoint("TOPLEFT", section.header, "BOTTOMLEFT", 3, -((index - 1) * 16)); row:SetPoint("RIGHT", section, "RIGHT", -3, 0)
        row:EnableMouse(true)
        row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); row.label:SetPoint("LEFT"); row.label:SetText(rowDefinition[2])
        row.value = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); row.value:SetPoint("RIGHT"); row.value:SetJustifyH("RIGHT")
        row.key = rowDefinition[1]
        row:SetScript("OnEnter", function(current)
            GameTooltip:SetOwner(current, "ANCHOR_RIGHT")
            local r, g, b = BCS:GetAccentColor()
            GameTooltip:SetText(current.label:GetText() or rowDefinition[2], r, g, b)
            GameTooltip:AddLine("Current: " .. tostring(current._value or "—"), 1, 1, 1)
            GameTooltip:AddLine(STAT_HELP[current.key] or "Character statistic.", 0.82, 0.82, 0.82, true)
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", GameTooltip_Hide)
        section.rows[#section.rows + 1] = row; self.rows[row.key] = row
    end
    section.header:SetScript("OnClick", function()
        if section.header._dragged then section.header._dragged = nil return end
        BCS.charDB.statsCollapsed[key] = not BCS.charDB.statsCollapsed[key]
        self:Layout(); self:Refresh()
    end)
    section.header:SetScript("OnDragStart", function(button) button._dragged = true; button:SetAlpha(0.55) end)
    section.header:SetScript("OnDragStop", function(button)
        button:SetAlpha(1)
        local _, cursorY = GetCursorPosition(); cursorY = cursorY / UIParent:GetEffectiveScale()
        local nearest, distance
        for otherKey, other in pairs(self.sections) do
            if other:IsShown() then
                local _, centerY = other.header:GetCenter()
                if centerY and (not distance or math.abs(cursorY - centerY) < distance) then nearest, distance = otherKey, math.abs(cursorY - centerY) end
            end
        end
        if nearest then self:MoveSection(key, nearest) end
        C_Timer.After(0, function() button._dragged = nil end)
    end)
    self.sections[key] = section
end

function M:Build()
    for key in pairs(SECTION_DEFS) do self:CreateSection(key) end
    self:Layout()
end

function M:Layout()
    if self.contentMode and self.contentMode ~= "stats" then
        for _, section in pairs(self.sections) do section:Hide() end
        return
    end
    local previous
    for _, key in ipairs(BCS.charDB.statsOrder) do
        local section = self.sections[key]
        local enabled = BCS.charDB.statsSections[key] ~= false
        section:SetShown(enabled)
        if enabled then
            section:ClearAllPoints()
            if previous then section:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -4) else section:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 6, -6) end
            local collapsed = BCS.charDB.statsCollapsed[key]
            local visibleRows = 0
            for _, row in ipairs(section.rows) do
                if not self.dynamicVisibility or self.dynamicVisibility[row.key] ~= false then visibleRows = visibleRows + 1 end
            end
            section:SetHeight(collapsed and 20 or (20 + (visibleRows * 16)))
            section.header.indicator:SetText(collapsed and "+" or "−")
            local rowIndex = 0
            for _, row in ipairs(section.rows) do
                local rowShown = not collapsed and (not self.dynamicVisibility or self.dynamicVisibility[row.key] ~= false)
                row:SetShown(rowShown)
                if rowShown then
                    row:ClearAllPoints()
                    row:SetPoint("TOPLEFT", section.header, "BOTTOMLEFT", 3, -(rowIndex * 16)); row:SetPoint("RIGHT", section, "RIGHT", -3, 0)
                    rowIndex = rowIndex + 1
                end
            end
            previous = section
        end
    end
end

function M:Values()
    local primaryName, primary = PrimaryStat()
    local _, equipped = GetAverageItemLevel(); local _, armor = UnitArmor("player")
    local durability = LowestDurability()
    local powerType, powerToken = UnitPowerType("player")
    self.rows.power.label:SetText(_G[powerToken] or powerToken or "Power"); self.rows.primary.label:SetText(primaryName)
    local attackBase, attackPositive, attackNegative = UnitAttackPower("player")
    local mainSpeed, offSpeed = UnitAttackSpeed("player")
    local spellPower = 0; for school = 2, 7 do spellPower = math.max(spellPower, SafeNumber(GetSpellBonusDamage, school)) end
    local stagger = C_PaperDollInfo and SafeNumber(C_PaperDollInfo.GetStaggerPercentage, "player") or SafeNumber(GetStaggerPercentage, "player")
    local movement, visibility = MovementValues()
    self.dynamicVisibility = visibility
    return {
        primary = BreakUpLargeNumbers(primary), stamina = BreakUpLargeNumbers(select(2, UnitStat("player", 3)) or 0), health = BreakUpLargeNumbers(UnitHealthMax("player") or 0),
        power = BreakUpLargeNumbers(UnitPowerMax("player", powerType) or 0), gcd = ("%.2fs"):format(1.5 / (1 + SafeNumber(GetHaste) / 100)),
        haste = RatingPercent(SafeNumber(GetHaste), SafeNumber(GetCombatRating, CR_HASTE_MELEE)), mastery = RatingPercent(SafeNumber(GetMasteryEffect), SafeNumber(GetCombatRating, CR_MASTERY)),
        critical = RatingPercent(SafeNumber(GetCritChance), SafeNumber(GetCombatRating, CR_CRIT_MELEE)), versatility = RatingPercent(SafeNumber(GetCombatRatingBonus, CR_VERSATILITY_DAMAGE_DONE), SafeNumber(GetCombatRating, CR_VERSATILITY_DAMAGE_DONE)),
        attackPower = BreakUpLargeNumbers((attackBase or 0) + (attackPositive or 0) + (attackNegative or 0)), attackSpeed = offSpeed and ("%.2f / %.2fs"):format(mainSpeed or 0, offSpeed) or ("%.2fs"):format(mainSpeed or 0),
        spellPower = BreakUpLargeNumbers(spellPower), armor = BreakUpLargeNumbers(armor or 0), dodge = ("%.2f%%"):format(SafeNumber(GetDodgeChance)), parry = ("%.2f%%"):format(SafeNumber(GetParryChance)),
        block = ("%.2f%%"):format(SafeNumber(GetBlockChance)), stagger = ("%.2f%%"):format(stagger), itemLevel = ("%.1f"):format(equipped or 0), durability = durability and (durability .. "%") or "—",
        leech = ("%.2f%%"):format(SafeNumber(GetLifesteal)), avoidance = ("%.2f%%"):format(SafeNumber(GetAvoidance)),
        speed = movement.speed, runSpeed = movement.runSpeed, groundMountSpeed = movement.groundMountSpeed, flightSpeed = movement.flightSpeed,
    }
end

function M:Refresh()
    if not self.frame or not BCS.charDB then return end
    self.frame:SetShown(CharacterFrame:IsShown() and PaperDollFrame:IsShown())
    if CharacterStatsPane then CharacterStatsPane:SetAlpha(0); CharacterStatsPane:EnableMouse(false) end
    if not self.frame:IsShown() then return end
    local bg, border = BCS.charDB.attributesBackgroundColor, BCS.charDB.borderColor
    local headingColor, attributeColor = BCS.charDB.attributesHeaderColor, BCS.charDB.attributesBodyColor
    self.frame:SetBackdropColor(bg[1], bg[2], bg[3], bg[4] or 1); self.frame:SetBackdropBorderColor(border[1], border[2], border[3], BCS.charDB.borderOpacity)
    if self.contentMode and self.contentMode ~= "stats" then
        for _, section in pairs(self.sections) do section:Hide() end
        return
    end
    local values = self:Values()
    self:Layout()
    for _, section in pairs(self.sections) do
        BCS.modules.Fonts:Apply(section.header.text, "attributesHeaderSize", "attributesHeaderFont")
        BCS.modules.Fonts:Apply(section.header.indicator, "attributesHeaderSize", "attributesHeaderFont")
        section.header.text:SetTextColor(headingColor[1], headingColor[2], headingColor[3], headingColor[4] or 1)
        section.header.indicator:SetTextColor(headingColor[1], headingColor[2], headingColor[3], headingColor[4] or 1)
        section.line:SetColorTexture(headingColor[1], headingColor[2], headingColor[3], 0.38)
    end
    for key, row in pairs(self.rows) do
        BCS.modules.Fonts:Apply(row.label, "attributesBodySize", "attributesBodyFont")
        BCS.modules.Fonts:Apply(row.value, "attributesBodySize", "attributesBodyFont")
        row.label:SetTextColor(attributeColor[1], attributeColor[2], attributeColor[3], attributeColor[4] or 1)
        row.value:SetTextColor(attributeColor[1], attributeColor[2], attributeColor[3], attributeColor[4] or 1)
        row._value = values[key] or "—"; row.value:SetText(row._value)
    end
end

function M:SetContentMode(mode)
    self.contentMode = mode or "stats"
    self:Refresh()
end

function M:Initialize()
    BCS:WhenCharacterUIReady(function()
        self.contentMode = "stats"
        self.frame = CreateDock(); self:Build()
        local events = CreateFrame("Frame")
        for _, event in ipairs({ "PLAYER_EQUIPMENT_CHANGED", "UNIT_STATS", "UNIT_MAXHEALTH", "UNIT_AURA", "COMBAT_RATING_UPDATE", "MASTERY_UPDATE", "SPEED_UPDATE", "LIFESTEAL_UPDATE", "AVOIDANCE_UPDATE", "PLAYER_SPECIALIZATION_CHANGED", "PLAYER_LOOT_SPEC_UPDATED", "PLAYER_TALENT_UPDATE", "PLAYER_MOUNT_DISPLAY_CHANGED", "PLAYER_STARTED_MOVING", "PLAYER_STOPPED_MOVING" }) do
            if event:find("^UNIT_") then events:RegisterUnitEvent(event, "player") else events:RegisterEvent(event) end
        end
        events:SetScript("OnEvent", function() if CharacterFrame:IsShown() then self:Refresh() end end)
        CharacterFrame:HookScript("OnShow", function() self:Refresh() end)
        PaperDollFrame:HookScript("OnShow", function() self:Refresh() end)
        PaperDollFrame:HookScript("OnHide", function() self.frame:Hide() end)
        self.events = events; self:Refresh()
    end)
end
