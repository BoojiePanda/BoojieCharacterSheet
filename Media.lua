local _, BCS = ...

-- Boojie is deliberately a consumer only. No media owned by another addon is
-- copied or addressed by file path here; enabled providers publish it to LSM.
BCS.media = {
    defaultFont = "Fonts\\FRIZQT__.TTF",
    types = { "font", "statusbar", "background", "border", "sound" },
    fallback = {
        font = "Fonts\\FRIZQT__.TTF",
        statusbar = "Interface\\Buttons\\WHITE8X8",
        background = "Interface\\Buttons\\WHITE8X8",
        border = "Interface\\Buttons\\WHITE8X8",
    },
}

local function SortedRegistry(shared, mediaType)
    local result = {}
    if shared then
        for name, path in pairs(shared:HashTable(mediaType) or {}) do
            result[#result + 1] = { name = name, path = path }
        end
    end
    table.sort(result, function(a, b) return a.name:lower() < b.name:lower() end)
    return result
end

function BCS:DiscoverMedia()
    local libStub = _G.LibStub
    local shared = libStub and libStub("LibSharedMedia-3.0", true)
    self.LSM = shared
    self.media.registry = {}
    for _, mediaType in ipairs(self.media.types) do
        self.media.registry[mediaType] = SortedRegistry(shared, mediaType)
    end

    local fonts = {
        ["Friz Quadrata"] = self.media.defaultFont,
        ["Arial Narrow"] = "Fonts\\ARIALN.TTF",
        ["Morpheus"] = "Fonts\\MORPHEUS.TTF",
        ["Skurri"] = "Fonts\\SKURRI.TTF",
        ["Legacy Serif"] = "Fonts\\2002.TTF",
        ["Friz Quadrata Cyrillic"] = "Fonts\\FRIZQT___CYR.TTF",
    }
    for _, entry in ipairs(self.media.registry.font) do fonts[entry.name] = entry.path end
    self.fonts = fonts
    return self.media.registry
end

function BCS:GetMediaSelectionTable()
    local account = self.db and self.db.media
    if account and account.useAccountWide then return account end
    return self.charDB and self.charDB.media
end

function BCS:GetMediaName(mediaType)
    local selected = self:GetMediaSelectionTable()
    local name = selected and selected[mediaType] or nil
    if name and (not self.LSM or not self.LSM:Fetch(mediaType, name, true)) then return nil end
    return name
end

function BCS:FetchMedia(mediaType)
    local name = self:GetMediaName(mediaType)
    if name and self.LSM then
        local path = self.LSM:Fetch(mediaType, name, true)
        if path then return path end
    end
    return self.media.fallback[mediaType]
end

function BCS:SetMediaName(mediaType, name)
    local selected = self:GetMediaSelectionTable()
    if selected then selected[mediaType] = name end
end

function BCS:OnSharedMediaRegistered(_, mediaType)
    if not self.media.registry[mediaType] or self._mediaRefreshPending then return end
    self._mediaRefreshPending = true
    C_Timer.After(0.1, function()
        self._mediaRefreshPending = nil
        self:DiscoverMedia()
        local settings = self.modules and self.modules.Settings
        if settings and settings.RefreshMediaLists then settings:RefreshMediaLists() end
    end)
end

function BCS:InitializeMedia()
    self:DiscoverMedia()
    if self.LSM and self.LSM.RegisterCallback then
        self.LSM.RegisterCallback(self, "LibSharedMedia_Registered", "OnSharedMediaRegistered")
    end
end
