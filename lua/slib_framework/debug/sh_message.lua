function slib.ConsoleMessage(prefix, message_type, ...)
	local tags = string.Explode('.', prefix)
	local stylized_prefix = ''
	local message_args = { ... }
	local message = ''

	if #tags == 0 or tags[1] == '.' then
		stylized_prefix = '[' .. prefix .. ']'
	else
		for i = 1, #tags do
			stylized_prefix = stylized_prefix .. '[' .. tags[i] .. ']'
		end
	end

	for i = 1, #message_args do
		message = message .. tostring(message_args[i])
	end

	if message_type == 'error' then
		ErrorNoHalt(stylized_prefix .. ' ' .. message .. '\n')
	else
		MsgN(stylized_prefix .. ' ' .. message)
	end
end

function slib.Log(...)
	slib.ConsoleMessage('SLIB.LOG', nil, ...)
end

function slib.Warning(...)
	slib.ConsoleMessage('SLIB.WARNING', nil, ...)
end

function slib.Error(...)
	slib.ConsoleMessage('SLIB.ERROR', 'error', ...)
end

function slib.DebugLog(...)
	if not slib.CvarCheckValue('slib_debug', 1) then return end
	slib.ConsoleMessage('SLIB.LOG', nil, ...)
end

function slib.DebugWarning(...)
	if not slib.CvarCheckValue('slib_debug', 1) then return end
	slib.ConsoleMessage('SLIB.WARNING', nil, ...)
end

function slib.DebugError(...)
	if not slib.CvarCheckValue('slib_debug', 1) then return end
	slib.ConsoleMessage('SLIB.ERROR', 'error', ...)
end