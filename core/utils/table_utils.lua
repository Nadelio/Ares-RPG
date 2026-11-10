local TableUtils = {}

function TableUtils.tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

function TableUtils.clone(value)
	if type(value) ~= "table" then
		return value
	end

	local copied = {}

	for key, nested in pairs(value) do
		copied[key] = TableUtils.clone(nested)
	end

	return copied
end

function TableUtils.contains(list, value)
	for _, item in ipairs(list or {}) do
		if item == value then
			return true
		end
	end

	return false
end

function TableUtils.append_unique(list, value)
	if not TableUtils.contains(list, value) then
		table.insert(list, value)
	end
end

function TableUtils.assert_data_only(value, path, seen)
	local value_type = type(value)
	path = path or "value"

	assert(
		value_type ~= "function" and value_type ~= "thread" and value_type ~= "userdata",
		path .. " must contain data only"
	)

	if value_type ~= "table" then
		return
	end

	seen = seen or {}
	assert(not seen[value], path .. " must not contain cyclic references")
	seen[value] = true

	for key, nested in pairs(value) do
		TableUtils.assert_data_only(key, path .. " key", seen)
		TableUtils.assert_data_only(nested, path .. "." .. tostring(key), seen)
	end

	seen[value] = nil
end

return TableUtils