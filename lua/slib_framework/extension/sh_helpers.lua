function slib.language(data, select_language)
	if not istable(data) then return '' end
	if select_language and data[select_language] then return data[select_language] end
	if CLIENT then
		local current_language = GetConVar('cl_language'):GetString()
		if data[current_language] then return data[current_language] end
	end
	if data['default'] then return data['default'] end
	return ''
end