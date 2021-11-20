local type = type
local tostring = tostring
local snet_Serialize = snet.Serialize
local util_Base64Encode = util.Base64Encode
local util_CRC = util.CRC
--

local function get_string_data(data)
	local datatype = type(data)

	if datatype == 'nil' then
		return ''
	end

	if datatype == 'string' then
		return data
	end

	if datatype == 'table' then
		return snet_Serialize(data, false)
	end

	if datatype == 'Vector' or datatype == 'Angle' then
		return data.x .. data.y .. data.z
	end

	if datatype == 'Color' then
		return data.r .. data.g .. data.b .. data.a
	end

	return tostring(data)
end

function slib.GetHash(data)
	local normalize_data = get_string_data(data)
	return util_Base64Encode(normalize_data)
end

function slib.GetHashSumm(data)
	local normalize_data = get_string_data(data)
	return util_CRC(normalize_data)
end