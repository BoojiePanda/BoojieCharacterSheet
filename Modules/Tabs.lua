local _, BCS = ...
local M = {}
BCS:RegisterModule("Tabs", M)

local TAB_MINIMUM_WIDTHS = { 104, 116, 100 }

local function ApplyTabFont(text)
    if not text or text._bcsApplyingFont then return end
    text._bcsApplyingFont = true
    BCS.modules.Fonts:Apply(text, "miscTextSize")
    text._bcsApplyingFont = nil
end

function M:EnforceWidths()
    for index = 1, 3 do
        local tab = _G["CharacterFrameTab" .. index]
        if tab and tab.Text then
            ApplyTabFont(tab.Text)
            local textWidth = tab.Text.GetUnboundedStringWidth and tab.Text:GetUnboundedStringWidth() or tab.Text:GetStringWidth()
            local width = math.max(TAB_MINIMUM_WIDTHS[index], math.ceil((textWidth or 0) + 28))
            tab._bcsDesiredWidth = width
            if math.abs(tab:GetWidth() - width) > 0.5 then tab:SetWidth(width) end
            tab.Text:ClearAllPoints()
            tab.Text:SetPoint("LEFT", tab, "LEFT", 10, 0)
            tab.Text:SetPoint("RIGHT", tab, "RIGHT", -10, 0)
            tab.Text:SetWordWrap(false)
            tab.Text:SetMaxLines(1)
        end
    end
    local first, second, third = CharacterFrameTab1, CharacterFrameTab2, CharacterFrameTab3
    if first and second and third then
        first:ClearAllPoints(); first:SetPoint("TOPLEFT", CharacterFrame, "BOTTOMLEFT", 8, 2)
        second:ClearAllPoints(); second:SetPoint("LEFT", first, "RIGHT", 3, 0)
        third:ClearAllPoints(); third:SetPoint("LEFT", second, "RIGHT", 3, 0)
    end
end

function M:Refresh()
    local selected = PanelTemplates_GetSelectedTab and PanelTemplates_GetSelectedTab(CharacterFrame)
    for index = 1, 3 do
        local tab = _G["CharacterFrameTab" .. index]
        if tab and tab.Text then
            BCS.modules.Theme:SetTabStyle(tab); BCS.modules.Fonts:Apply(tab.Text, "miscTextSize")
            tab.Text:SetTextColor(index == selected and 1 or 0.82, index == selected and 0.553 or 0.82, index == selected and 0.631 or 0.82)
            if not tab._bcsRefreshHook then
                tab:HookScript("OnClick", function()
                    local character = BCS.modules.CharacterFrame
                    if character and character.Apply then character:Apply() end
                    if character and character.ScheduleApply then character:ScheduleApply() end
                end)
                tab._bcsRefreshHook = true
            end
        end
    end
    self:EnforceWidths()
end

function M:Initialize()
    BCS:WhenCharacterUIReady(function()
        for index = 1, 3 do
            local tab = _G["CharacterFrameTab" .. index]
            local text = tab and tab.Text
            if text and not text._bcsFontGuard then
                text._bcsFontGuard = true
                hooksecurefunc(text, "SetFont", function(current)
                    if not current._bcsApplyingFont then ApplyTabFont(current) end
                end)
            end
        end
        self:EnforceWidths()
        CharacterFrame:HookScript("OnShow", function() self:EnforceWidths() end)
    end)
end
