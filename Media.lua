local _, BCS = ...

BCS.media = { defaultFont = "Fonts\\FRIZQT__.TTF" }

function BCS:DiscoverFonts()
    local fonts = {
        ["Friz Quadrata"] = self.media.defaultFont,
        ["Arial Narrow"] = "Fonts\\ARIALN.TTF",
        ["Morpheus"] = "Fonts\\MORPHEUS.TTF",
        ["Skurri"] = "Fonts\\SKURRI.TTF",
        ["Legacy Serif"] = "Fonts\\2002.TTF",
        ["Friz Quadrata Cyrillic"] = "Fonts\\FRIZQT___CYR.TTF",
    }
    if C_AddOns and C_AddOns.GetAddOnInfo and C_AddOns.GetAddOnInfo("SharedMedia_MyMedia") then
        fonts["Bellota Regular"] = "Interface\\AddOns\\SharedMedia_MyMedia\\font\\Bellota-Regular.ttf"
        fonts["Bellota Bold"] = "Interface\\AddOns\\SharedMedia_MyMedia\\font\\Bellota-Bold.ttf"
    end
    local libStub = _G.LibStub
    local shared = libStub and libStub("LibSharedMedia-3.0", true)
    if shared then
        for _, name in ipairs(shared:List("font") or {}) do fonts[name] = shared:Fetch("font", name) end
    end
    self.fonts = fonts
    return fonts
end
