local _, BCS = ...

BCS.name = "Boojie Character Sheet"
BCS.defaults = {
    schemaVersion = 1,
    showMinimapButton = true,
    minimap = { minimapPos = 52.84324568479437 },
    characterSheetScale = 1,
    media = { useAccountWide = false },
    typography = { useAccountWide = false, font = "Fonts\\FRIZQT__.TTF",
        gearNameSize = 14, miscTextSize = 12, guildSize = 16, reputationCurrencyHeaderSize = 14,
        attributesHeaderFont = nil, attributesHeaderSize = 14, attributesBodyFont = nil, attributesBodySize = 12,
        characterNameSize = 16, slotLabelSize = 12 },
    collapseState = { schemaVersion = 1, reputation = {}, currency = {} },
}
BCS.characterDefaults = {
    textColor = { 1, 1, 1, 1 },
    accentColor = { 1, 0.553, 0.631, 1 },
    characterSheetBackgroundColor = { 0, 0, 0, 1 },
    attributesBackgroundColor = { 0.1294117718935013, 0.1294117718935013, 0.1294117718935013, 1 },
    borderColor = { 0.2274509966373444, 0.2784313857555389, 0.3019607961177826, 1 }, borderOpacity = 1,
    fontOutline = "OUTLINE", equipmentLabelsEnabled = true,
    gearItemNameEnabled = true, gearUpgradeLevelEnabled = true, gearHideMaxUpgrade = false,
    gearUpgradeTrackColorsEnabled = true,
    gemNameEnabled = true, gemIconEnabled = true, enchantEnabled = true,
    liveCharacterViewEnabled = true,
    useElvUIReputationTexture = true,
    attributesHeaderColor = { 1, 0.553, 0.631, 1 }, attributesBodyColor = { 0.32, 0.82, 0.95, 1 },
    statsSections = { attributes = true, secondary = true, attack = true, defense = false, general = true },
    statsCollapsed = { attributes = false, secondary = false, attack = false, defense = false, general = false },
    statsOrder = { "general", "attributes", "secondary", "attack", "defense" },
    media = {},
    equipmentTopPadding = 12, equipmentBottomPadding = 12,
    gearTooltipScale = 100,
    typography = { font = "Fonts\\FRIZQT__.TTF",
        gearNameSize = 12, miscTextSize = 12, guildSize = 14, reputationCurrencyHeaderSize = 14,
        attributesHeaderFont = "Fonts\\FRIZQT__.TTF", attributesHeaderSize = 16,
        attributesBodyFont = nil, attributesBodySize = 12, characterNameSize = 16, slotLabelSize = 11 },
}
