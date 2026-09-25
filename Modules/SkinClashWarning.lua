local _, BCS = ...
local M = {}
BCS:RegisterModule("SkinClashWarning", M)

local function Enabled(value)
    return value ~= false and value ~= nil
end

local function DetectConflicts()
    local elvui = _G.ElvUI
    local E = type(elvui) == "table" and elvui[1]
    local private = E and E.private
    local elvBlizzard = private and private.skins and private.skins.blizzard
    local elvCharacter = elvBlizzard
        and Enabled(elvBlizzard.enable)
        and Enabled(elvBlizzard.character)

    local wtSkins = private and private.WT and private.WT.skins
    local wtBlizzard = wtSkins and wtSkins.blizzard
    local windToolsCharacter = elvCharacter
        and Enabled(wtSkins.enable)
        and wtBlizzard
        and Enabled(wtBlizzard.enable)
        and Enabled(wtBlizzard.character)

    return elvCharacter and true or false, windToolsCharacter and true or false
end

local function Warn()
    local elvCharacter, windToolsCharacter = DetectConflicts()
    if not elvCharacter and not windToolsCharacter then return end

    -- ChatFrame1 owns the default General tab. Writing to it directly keeps the
    -- compatibility notice out of combat text, floating windows, and UI errors.
    local chat = _G.ChatFrame1 or _G.DEFAULT_CHAT_FRAME
    if not chat or not chat.AddMessage then return end

    chat:AddMessage(BCS:AccentText("Boojie Character Sheet:") .. " |cffff3333SKIN CONFLICT DETECTED!|r Another addon is also skinning the Character Sheet.")
    if elvCharacter then
        chat:AddMessage("  |cffff3333ElvUI Character Frame skin enabled:|r Type |cff00ccff/ec|r, open |cffffffffSkins > Blizzard|r, and disable |cffff3333Character Frame|r.")
    end
    if windToolsCharacter then
        chat:AddMessage("  |cffff3333WindTools Character skin enabled:|r Type |cff00ccff/ec|r, open |cffffffffWindTools > Skins > Blizzard|r, and disable |cffff3333Character|r.")
    end
    chat:AddMessage("  |cffffcc00Reload the UI after changing either setting.|r")
end

function M:Initialize()
    local events = CreateFrame("Frame")
    events:RegisterEvent("PLAYER_LOGIN")
    events:SetScript("OnEvent", function(frame)
        frame:UnregisterEvent("PLAYER_LOGIN")
        C_Timer.After(1, Warn)
    end)
    self.events = events
end
