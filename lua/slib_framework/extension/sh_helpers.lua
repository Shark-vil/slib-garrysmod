local engine_TickInterval = engine.TickInterval
local math_sqrt = math.sqrt

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

function slib.chance(percent)
	if percent < 0 then percent = 0 end
	if percent > 100  then percent = 100 end
	return percent >= math.random(1, 100)
end

function slib.GetServerTickrate()
	return 1 / engine_TickInterval()
end

function slib.magnitude(vec)
	local magnitude = vec
	magnitude = magnitude.x ^ 2 + magnitude.y ^ 2 + magnitude.z ^ 2
	magnitude = math_sqrt(magnitude)
	return magnitude
end