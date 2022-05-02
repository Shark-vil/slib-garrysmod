local originalNetReceive = net.Receive

function net.Receive(messageName, func)
	return originalNetReceive(messageName, function(...)
		if hook.Run('OnCallNetMessage', messageName, ...) == false then return end
		return func(...)
	end)
end