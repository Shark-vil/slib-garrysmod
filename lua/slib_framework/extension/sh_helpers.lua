local engine_TickInterval = engine.TickInterval
local math_sqrt = math.sqrt
local xpcall = xpcall
local hook_Run = hook.Run
local debug_traceback = debug.traceback
local ErrorNoHalt = ErrorNoHalt
local table_remove = table.remove
local unpack = unpack
local string_Trim = string.Trim
local tostring = tostring
local math_random = math.random
local type = type
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
	return percent >= math_random(1, 100)
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

function slib.StringLinePairs(text)
	if type(text) ~= 'string' then
		text = tostring(text)
	end

	local line_index = 1
	local text_lines = {}
	local temp_data = text .. '\n'

	for text_line in temp_data:gmatch('(.-)\n') do
		if not text_line then continue end

		text_line = string_Trim(text_line)
		if #text_line == 0 then continue end

		text_lines[line_index] = text_line
		line_index = line_index + 1
	end

	local parse_index = 0
	return function()
		parse_index = parse_index + 1
		if parse_index <= line_index and text_lines[parse_index] ~= nil then
			return parse_index, text_lines[parse_index]
		end
	end
end

function slib.SafeHookRun(hook_type, ...)
	local result = { xpcall(hook_Run, function(err)
		ErrorNoHalt(debug_traceback(err))
	end, hook_type, ...) }

	local succ = result[1]
	if not succ then return nil end

	table_remove(result, 1)
	return unpack(result)
end