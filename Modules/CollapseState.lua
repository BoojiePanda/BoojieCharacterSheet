local _, BCS = ...
local M = { restoring = {}, pending = {}, hooked = {} }
BCS:RegisterModule("CollapseState", M)

local function Normalize(name)
    return (tostring(name or ""):lower():gsub("[%c%s]+", " "):match("^%s*(.-)%s*$")) or ""
end

local function SafeCall(func, ...)
    if type(func) ~= "function" then return end
    local ok, value = pcall(func, ...)
    if ok then return value end
end

local function Key(info, path, idField)
    local id = info and tonumber(info[idField])
    return id and id > 0 and ("id:" .. id) or ("path:" .. table.concat(path, "\31"))
end

function M:Touch(kind, key, expanded)
    if not key then return end
    local entry = self.db[kind][key] or {}
    entry.expanded, entry.lastSeen, entry.misses = not not expanded, time(), 0
    self.db[kind][key] = entry
end

function M:MarkMissing(kind, seen)
    local now = time()
    for key, entry in pairs(self.db[kind]) do
        if seen[key] then entry.lastSeen, entry.misses = now, 0
        else
            entry.misses = (tonumber(entry.misses) or 0) + 1
            if entry.misses >= 50 and tonumber(entry.lastSeen) and now - entry.lastSeen > 31536000 then self.db[kind][key] = nil end
        end
    end
end

function M:ReputationRows()
    local api, rows, parents = C_Reputation, {}, {}
    if not api or not api.GetNumFactions then return rows end
    for index = 1, api.GetNumFactions() do
        local info = SafeCall(api.GetFactionDataByIndex, index)
        if info and info.isHeader then
            local depth = info.isHeaderWithRep and 2 or 1
            parents[depth] = Normalize(info.name)
            for n = depth + 1, #parents do parents[n] = nil end
            local path = {}; for n = 1, depth do path[n] = parents[n] end
            rows[#rows + 1] = { index = index, key = Key(info, path, "factionID"), expanded = not info.isCollapsed }
        end
    end
    return rows
end

function M:CurrencyRows()
    local api, rows, parents = C_CurrencyInfo, {}, {}
    if not api or not api.GetCurrencyListSize then return rows end
    for index = 1, api.GetCurrencyListSize() do
        local info = SafeCall(api.GetCurrencyListInfo, index)
        if info and info.isHeader then
            local depth = (tonumber(info.currencyListDepth) or 0) + 1
            parents[depth] = Normalize(info.name)
            for n = depth + 1, #parents do parents[n] = nil end
            local path = {}; for n = 1, depth do path[n] = parents[n] end
            rows[#rows + 1] = { index = index, key = Key(info, path, "currencyID"), expanded = not not info.isHeaderExpanded }
        end
    end
    return rows
end

function M:CaptureReputation(row, delayed)
    if self.restoring.reputation then return end
    local index = row and (row.factionIndex or (row.elementData and row.elementData.factionIndex))
    if not index then return end
    if not delayed then
        if self.pending.reputation then self.pending.reputation:Cancel(); self.pending.reputation = nil end
        C_Timer.After(0, function() self:CaptureReputation({ factionIndex = index }, true) end)
        return
    end
    for _, item in ipairs(self:ReputationRows()) do
        if item.index == index then self:Touch("reputation", item.key, item.expanded) break end
    end
end

function M:CaptureCurrency(row, delayed)
    if self.restoring.currency then return end
    local index = row and row.elementData and row.elementData.currencyIndex
    if not index then return end
    if not delayed then
        if self.pending.currency then self.pending.currency:Cancel(); self.pending.currency = nil end
        C_Timer.After(0, function() self:CaptureCurrency({ elementData = { currencyIndex = index } }, true) end)
        return
    end
    for _, item in ipairs(self:CurrencyRows()) do
        if item.index == index then self:Touch("currency", item.key, item.expanded) break end
    end
end

function M:RestoreReputation()
    local api = C_Reputation
    if self.restoring.reputation or not api or not api.ExpandAllFactionHeaders then return end
    self.restoring.reputation = true
    local defaults = {}; for _, row in ipairs(self:ReputationRows()) do defaults[row.key] = row.expanded end
    SafeCall(api.ExpandAllFactionHeaders)
    local rows, seen = self:ReputationRows(), {}
    for _, row in ipairs(rows) do seen[row.key] = true end
    for index = #rows, 1, -1 do
        local row, saved = rows[index], self.db.reputation[rows[index].key]
        local wanted = saved ~= nil and saved.expanded or defaults[row.key]
        if wanted == false then SafeCall(api.CollapseFactionHeader, row.index) end
    end
    self:MarkMissing("reputation", seen)
    self.restoring.reputation = false
end

function M:RestoreCurrency()
    local api = C_CurrencyInfo
    if self.restoring.currency or not api or not api.ExpandCurrencyList then return end
    self.restoring.currency = true
    local defaults, rows = {}, self:CurrencyRows()
    for _, row in ipairs(rows) do defaults[row.key] = row.expanded end
    local index = 1
    while index <= api.GetCurrencyListSize() do
        local info = SafeCall(api.GetCurrencyListInfo, index)
        if info and info.isHeader and not info.isHeaderExpanded then SafeCall(api.ExpandCurrencyList, index, true) end
        index = index + 1
    end
    rows = self:CurrencyRows()
    local seen = {}; for _, row in ipairs(rows) do seen[row.key] = true end
    for index = #rows, 1, -1 do
        local row, saved = rows[index], self.db.currency[rows[index].key]
        local wanted = saved ~= nil and saved.expanded or defaults[row.key]
        if wanted == false then SafeCall(api.ExpandCurrencyList, row.index, false) end
    end
    self:MarkMissing("currency", seen)
    self.restoring.currency = false
end

function M:Schedule(kind, delay)
    if self.pending[kind] then self.pending[kind]:Cancel() end
    self.pending[kind] = C_Timer.NewTimer(delay or 0.15, function()
        self.pending[kind] = nil
        if kind == "reputation" then self:RestoreReputation() else self:RestoreCurrency() end
    end)
end

function M:Hook(owner, method, callback, key)
    if self.hooked[key] or type(owner) ~= "table" or type(owner[method]) ~= "function" then return end
    hooksecurefunc(owner, method, callback); self.hooked[key] = true
end

function M:InstallHooks()
    self:Hook(ReputationHeaderMixin, "ToggleCollapsed", function(row) self:CaptureReputation(row) end, "repHeader")
    self:Hook(ReputationSubHeaderMixin, "ToggleCollapsed", function(row) self:CaptureReputation(row) end, "repSubHeader")
    self:Hook(ReputationHeaderMixin, "OnClick", function(row) self:CaptureReputation(row) end, "repHeaderClick")
    self:Hook(ReputationSubHeaderMixin, "OnClick", function(row) self:CaptureReputation(row) end, "repSubHeaderClick")
    self:Hook(TokenHeaderMixin, "ToggleCollapsed", function(row) self:CaptureCurrency(row) end, "currencyHeader")
    self:Hook(TokenSubHeaderMixin, "ToggleCollapsed", function(row) self:CaptureCurrency(row) end, "currencySubHeader")
end

local function ImportTable(target, source)
    local imported = false
    if next(target) == nil and type(source) == "table" then
        for key, entry in pairs(source) do
            if type(key) == "string" and type(entry) == "table" and type(entry.expanded) == "boolean" then
                target[key] = { expanded = entry.expanded, lastSeen = tonumber(entry.lastSeen), misses = tonumber(entry.misses) or 0 }
                imported = true
            end
        end
    end
    return imported
end

function M:MigrateLegacy()
    local legacy = _G.BoojieCollapseKeeperDB
    if self.db.legacyImportComplete or type(legacy) ~= "table" then return false end
    local imported = ImportTable(self.db.reputation, legacy.reputation)
    imported = ImportTable(self.db.currency, legacy.currency) or imported
    self.db.legacyImportComplete = true
    return imported
end

function M:Initialize()
    self.db = BCS.db.collapseState
    local login = CreateFrame("Frame")
    login:RegisterEvent("PLAYER_LOGIN")
    login:SetScript("OnEvent", function()
        local imported = self:MigrateLegacy()
        if imported and not self.db.migrationNoticeShown then
            BCS:Print(BCS.L.MIGRATED)
            self.db.migrationNoticeShown = true
        end
        if C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("WarbandNexus") then
            self.warbandNexusCompatibility = true
            return
        end
        BCS:WhenCharacterUIReady(function()
            self:InstallHooks(); self:Schedule("reputation"); self:Schedule("currency")
        end)
    end)
    self.loginFrame = login
end
