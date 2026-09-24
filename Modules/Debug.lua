local _, BCS = ...
local M = {}
BCS:RegisterModule("Debug", M); BCS.Debug = M
function M:Report()
    local collapse = BCS.modules.CollapseState
    local rep, currency = 0, 0
    for _ in pairs(BCS.db.collapseState.reputation) do rep = rep + 1 end
    for _ in pairs(BCS.db.collapseState.currency) do currency = currency + 1 end
    BCS:Print(("Debug: schema=%s, reputation=%d, currency=%d, legacy=%s, warbandNexus=%s, CharacterFrame=%s, settingsButton=%s"):format(
        tostring(BCS.db.schemaVersion), rep, currency, tostring(BCS.db.collapseState.legacyImportComplete == true),
        tostring(collapse.warbandNexusCompatibility == true), tostring(CharacterFrame ~= nil),
        tostring(BoojieCharacterSheetSettingsButton ~= nil)))
end
