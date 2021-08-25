function slib.TypeValidate(value, typename)
	if type(value) ~= typename then
		error('The type of the variable is "' .. tostring(value) .. '", the expected type is "' .. typename .. '"')
	end
end