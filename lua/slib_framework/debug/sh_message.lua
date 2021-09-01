function slib.ConsoleMessage(prefix, ...)
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

	MsgN(stylized_prefix .. ' ' .. message)
end

function slib.Log(...)
	if not slib.CvarCheckValue('slib_debug', 1) then return end
	slib.ConsoleMessage('SLIB.LOG', ...)
end

function slib.Warning(...)
	if not slib.CvarCheckValue('slib_debug', 1) then return end
	slib.ConsoleMessage('SLIB.WARNING', ...)
end

function slib.Error(...)
	if not slib.CvarCheckValue('slib_debug', 1) then return end
	slib.ConsoleMessage('SLIB.ERROR', ...)
end