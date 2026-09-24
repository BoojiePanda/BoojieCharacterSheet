local _, BCS = ...
local M = { providers = {} }
BCS:RegisterModule("DockRegistry", M)

function M:Register(id, provider)
    if type(id) ~= "string" or type(provider) ~= "table" then return false end
    self.providers[id] = provider
    if BCS.modules.AddonButtonDock then BCS.modules.AddonButtonDock:Refresh() end
    return true
end
function M:Unregister(id)
    self.providers[id] = nil
    if BCS.modules.AddonButtonDock then BCS.modules.AddonButtonDock:Refresh() end
end
function M:Ordered()
    local list = {}; for id, provider in pairs(self.providers) do list[#list + 1] = { id = id, provider = provider } end
    table.sort(list, function(a, b) return (a.provider.order or 100) < (b.provider.order or 100) end)
    return list
end

_G.BoojieCharacterSheet_DockAPI = {
    Register = function(id, provider) return M:Register(id, provider) end,
    Unregister = function(id) M:Unregister(id) end,
}
