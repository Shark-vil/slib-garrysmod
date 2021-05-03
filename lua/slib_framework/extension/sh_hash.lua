function slib.GetHash(data)
	local datatype = type(data)

	if datatype == 'nil' then
		return ''
	end

	if datatype == 'string' then
		return data
	end

	if datatype == 'table' then
		return util.Base64Encode(util.TableToJSON(data))
	end

	if datatype == 'Vector' or datatype == 'Angle' then
		return util.Base64Encode(data.x .. data.y .. data.z)
	end

	return util.Base64Encode(tostring(data))
end