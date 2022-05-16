local originalNetReceive = net.Receive

local function GetCallbackFunction(messageName, func)
	return function(...)
		if hook.Run('OnCallNetMessage', messageName, ...) == false then return end
		return func(...)
	end
end

function net.Receive(messageName, func, ...)
	return originalNetReceive(messageName, GetCallbackFunction(messageName, func), ...)
end