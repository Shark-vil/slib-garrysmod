local function get_string_data(data)
	local datatype = type(data)

	if datatype == 'nil' then
		return ''
	end

	if datatype == 'string' then
		return data
	end

	if datatype == 'table' then
		return util.TableToJSON(data)
	end

	if datatype == 'Vector' or datatype == 'Angle' then
		return tostring(data.x) .. tostring(data.y) .. tostring(data.z)
	end

	if datatype == 'Color' then
		return tostring(data.r) .. tostring(data.g) .. tostring(data.b) .. tostring(data.a)
	end

	return tostring(data)
end

function slib.GetHash(data)
	local normalize_data = get_string_data(data)
	return util.Base64Encode(normalize_data)
end

function slib.GetHashSumm(data)
	local normalize_data = get_string_data(data)
	return util.CRC(normalize_data)
end