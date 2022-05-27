local error_color = Color(255, 115, 115, 200)
local warning_color = Color(250, 205, 81, 200)
local log_color = Color(219, 241, 245, 200)
local debug_traceback = debug.traceback

local function ConsoleMessage(prefix, message_type, ...)
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
		MsgC(error_color, stylized_prefix .. ' ' .. debug_traceback(message, 3) .. '\n')
		ErrorNoHalt()
	elseif message_type == 'warning' then
		MsgC(warning_color, stylized_prefix .. ' ' .. debug_traceback(message, 3) .. '\n')
	else
		MsgC(log_color, stylized_prefix .. ' ' .. message .. '\n')
	end
end

function slib.Log(...)
	ConsoleMessage('LOG', 'log', ...)
end

function slib.Warning(...)
	ConsoleMessage('WARNING', 'warning', ...)
end

function slib.Error(...)
	ConsoleMessage('ERROR', 'error', ...)
end

function slib.DebugLog(...)
	if not slib.CvarCheckValue('slib_debug', 1) then return end
	ConsoleMessage('DEBUG LOG', 'log', ...)
end

function slib.DebugWarning(...)
	if not slib.CvarCheckValue('slib_debug', 1) then return end
	ConsoleMessage('DEBUG WARNING', 'warning', ...)
end

function slib.DebugError(...)
	if not slib.CvarCheckValue('slib_debug', 1) then return end
	ConsoleMessage('DEBUG ERROR', 'error', ...)
end