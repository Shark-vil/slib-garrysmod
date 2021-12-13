local engine_TickInterval = engine.TickInterval
local math_sqrt = math.sqrt
--
local language_codes = {
	['bg'] = 'bulgarian',
	['cs'] = 'czech',
	['da'] = 'danish',
	['de'] = 'german',
	['el'] = 'greek',
	['en'] = 'english',
	['en-pt'] = 'pirate english',
	['es-es'] = 'spanish',
	['et'] = 'estonian',
	['fi'] = 'finnish',
	['fr'] = 'french',
	['he'] = 'hebrew',
	['hr'] = 'croatian',
	['hu'] = 'hungarian',
	['it'] = 'italian',
	['ja'] = 'japanese',
	['ko'] = 'korean',
	['lt'] = 'lithuanian',
	['nl'] = 'dutch',
	['no'] = 'norwegian',
	['pl'] = 'polish',
	['pt-br'] = 'portuguese (brazil)',
	['pt-pt'] = 'portuguese (portugal)',
	['ru'] = 'russian',
	['sk'] = 'slovak',
	['sv-se'] = 'swedish',
	['th'] = 'thai',
	['tr'] = 'turkish',
	['uk'] = 'ukrainian',
	['vi'] = 'vietnamese',
	['zh-cn'] = 'chinese simplified',
	['zh-tw'] = 'chinese traditional',
}

function slib.GetLanguageCode(select_language)
	local _select_language = tostring(select_language):lower()
	for code, value in pairs(language_codes) do
		if value == _select_language or code == _select_language then return code, value end
	end
end

function slib.language(data, select_language)
	if not istable(data) then return '' end

	if select_language and isstring(select_language) then
		if select_language and data[select_language] then return data[select_language] end

		local code, lang = slib.GetLanguageCode(select_language)
		if code and data[code] then return data[code] end
		if lang and data[lang] then return data[lang] end
	end

	if CLIENT then
		local current_language = GetConVar('cl_language'):GetString()
		if data[current_language] then return data[current_language] end

		local code, lang = slib.GetLanguageCode(current_language)
		if code and data[code] then return data[code] end
		if lang and data[lang] then return data[lang] end
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