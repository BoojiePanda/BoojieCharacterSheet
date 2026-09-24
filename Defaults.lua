local _, BCS = ...

BCS.name = "Boojie Character Sheet"
BCS.defaults = {
    schemaVersion = 1,
    minimapAngle = 45,
    settingsWindowSnapped = false,
    typography = { useAccountWide = false, font = nil, gearNameSize = 12, miscTextSize = 12, guildSize = 14, reputationCurrencyHeaderSize = 14,
        attributesHeaderFont = nil, attributesHeaderSize = 14, attributesBodyFont = nil, attributesBodySize = 12,
        characterNameSize = 14, slotLabelSize = 10 },
    collapseState = { schemaVersion = 1, reputation = {}, currency = {} },
}
BCS.characterDefaults = {
    textColor = { 0.92, 0.92, 0.92, 1 },
    accentColor = { 1, 0.553, 0.631, 1 }, backgroundColor = { 0.035, 0.035, 0.045, 1 },
    backgroundOpacity = 0.92, borderColor = { 0.24, 0.24, 0.30, 1 }, borderOpacity = 1,
    fontOutline = "OUTLINE", equipmentLabelsEnabled = true,
    gearItemNameEnabled = true, gearUpgradeLevelEnabled = true, gearHideMaxUpgrade = false,
    gearUpgradeTrackColorsEnabled = true,
    gemNameEnabled = true, gemIconEnabled = true, enchantEnabled = true,
    liveCharacterViewEnabled = true,
    attributesHeaderColor = { 1, 0.553, 0.631, 1 }, attributesBodyColor = { 0.32, 0.82, 0.95, 1 },
    statsSections = { attributes = true, secondary = true, attack = true, defense = true, general = true },
    statsCollapsed = { attributes = false, secondary = false, attack = false, defense = false, general = false },
    statsOrder = { "general", "attributes", "secondary", "attack", "defense" },
    restrainedTabsEnabled = true,
    characterFramePosition = nil, settingsPosition = nil,
    equipmentTopPadding = 3, equipmentBottomPadding = 3,
    gearTooltipScale = 100,
    typography = { font = nil, gearNameSize = 12, miscTextSize = 12, guildSize = 14, reputationCurrencyHeaderSize = 14,
        attributesHeaderFont = nil, attributesHeaderSize = 14, attributesBodyFont = nil, attributesBodySize = 12,
        characterNameSize = 14, slotLabelSize = 10 },
}
