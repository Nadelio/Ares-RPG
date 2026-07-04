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

return TableUtils