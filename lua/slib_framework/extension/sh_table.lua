local type = type
local next = next
local table_Random = table.Random
local table_Count = table.Count
local table_remove = table.remove
local math_random = math.random
--

function table.WhereHasValue(t, condition)
	for k, v in next, t do
		if condition(k, v) then return true end
	end

	return false
end

function table.Find(t, find_value)
	for k, v in next, t do
		if find_value == v then return k, v end
	end

	return -1, nil
end

function table.WhereFind(t, condition)
	for k, v in next, t do
		if condition(k, v) then return k, v end
	end

	return -1, nil
end

function table.RandomOmit(t, v)
	if v == nil then return table_Random(t) end
	local count = table_Count(t)
	if count == 0 then return nil end

	if count == 1 then
		local first_value = table.GetFirstValueByPairs(t)
		if first_value == v then return nil end

		return first_value
	end

	local random_value = v
	repeat
		random_value = table_Random(t)
	until random_value ~= v

	return random_value
end

function table.equals(t1, t2)
	if type(t1) ~= 'table' or type(t2) ~= 'table' then return false end

	for k, v in next, t1 do
		if type(v) == 'table' then
			if not table.equals(v, t2[k]) then return false end
		elseif v ~= t2[k] then
			return false
		end
	end

	return true
end

function table.GetFirstValueByPairs(t)
	for k, v in next, t do
		return v
	end

	return nil
end

function table.GetFirstKeyByPairs(t)
	for k, v in next, t do
		return k
	end

	return nil
end

-- function table.RemoveByValue(t, val)
--    local tbl = {}
--    local deleted = false
--    for k, v in next, t do
--       if deleted or v ~= val then
--          tbl[ k ] = v
--       else
--          deleted = true
--       end
--    end
--    return tbl
-- end

function table.RemoveAllByValue(t, val)
	local tbl = {}

	for k, v in next, t do
		if v ~= val then
			tbl[k] = v
		end
	end

	return tbl
end

function table.RemoveLastValue(t)
	if #t == 0 then return end
	table_remove(t, #t)
end

function table.RemoveFirstValue(t)
	if #t == 0 then return end
	table_remove(t, 1)
end

function table.RandomOpt(t)
	local keys = {}
	local index_count = 0
	for k, _ in next, t do
		index_count = index_count + 1
		keys[index_count] = k
	end

	local key = keys[math_random(index_count)]
	return t[key], key
end