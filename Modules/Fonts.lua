local _, BCS = ...
local M = {}
BCS:RegisterModule("Fonts", M)

function M:Apply(fontString, sizeKind, fontKind)
    if not fontString or not fontString.SetFont then return end
    fontString:SetFont(BCS:GetTypography(fontKind or "font"), BCS:GetTypography(sizeKind or "miscTextSize"), BCS.charDB.fontOutline)
    fontString:SetTextColor(unpack(BCS.charDB.textColor))
end
