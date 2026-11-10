local ImmutableTable = {}

--- Create a table that cannot be modified, will error on `__newindex()`\
--- Returns the table, now made immutable\
--- Use Lua 5.4's `<const>` syntax to prevent entire table from being reassigned at runtime, this function only affects table fields
--- @param table table
--- @return table
function ImmutableTable.new(table)
    if type(table) ~= "table" then return table end

    local protected_copy = {}
    for key, value in pairs(table) do
        protected_copy[key] = ImmutableTable.new(value)
    end

    return setmetatable({}, {
        __index = protected_copy,
        __newindex = function()
            error("Attempted to modify immutable table", 2)
        end,
        __pairs = function() return pairs(protected_copy) end,
        __metatable = false
    })
end

return ImmutableTable