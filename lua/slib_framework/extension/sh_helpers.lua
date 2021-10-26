function slib.language(data)
	if not istable(data) then return '' end
	if CLIENT then
		local current_language = GetConVar('cl_language'):GetString()
		if data[current_language] then return data[current_language] end
	end
	if data['default'] then return data['default'] end
	return ''
end