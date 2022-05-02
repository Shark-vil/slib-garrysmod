local originalConcommandAdd = concommand.Add

function concommand.Add(name, func)
	return originalConcommandAdd(name, function(...)
		if hook.Run('OnCallCommand', name, ...) == false then return end
		return func(...)
	end)
end