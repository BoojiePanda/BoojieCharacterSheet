local function Resolve(account, character, defaults, key)
    local value = account.useAccountWide and account[key] or character[key]
    return value == nil and defaults[key] or value
end
assert(Resolve({ useAccountWide = false, gearNameSize = 20 }, { gearNameSize = 13 }, { gearNameSize = 12 }, "gearNameSize") == 13)
assert(Resolve({ useAccountWide = true, gearNameSize = 20 }, { gearNameSize = 13 }, { gearNameSize = 12 }, "gearNameSize") == 20)
assert(Resolve({ useAccountWide = false }, {}, { gearNameSize = 12 }, "gearNameSize") == 12)
