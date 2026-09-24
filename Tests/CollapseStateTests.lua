local function Valid(entry) return type(entry) == "table" and type(entry.expanded) == "boolean" end
assert(Valid({ expanded = true }))
assert(Valid({ expanded = false }))
assert(not Valid({ expanded = 1 }))
assert(not Valid("expanded"))

local function Path(parts) return "path:" .. table.concat(parts, "\31") end
assert(Path({ "root", "child" }) ~= Path({ "other", "child" }))
