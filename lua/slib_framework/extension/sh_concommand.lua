local originalConcommandAdd = concommand.Add

local function GetCallbackFunction(name, func)
	return function(...)
		if hook.Run('slib.OnCallCommand', name, ...) == false then return end
		return func(...)
	end
end

function concommand.Add(name, func, ...)
	return originalConcommandAdd(name, GetCallbackFunction(name, func), ...)
end