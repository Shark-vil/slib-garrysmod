local snet = slib.Components.Network
local CLIENT = CLIENT
--

function snet.Invoke(name, receiver, ...)
	if CLIENT then
		return snet.Request(name, ...).InvokeServer()
	end
	return snet.Request(name, ...).Invoke(receiver)
end

function snet.InvokeAll(name, ...)
	return snet.Request(name, ...).InvokeAll()
end

function snet.InvokeIgnore(name, receiver, ...)
	return snet.Request(name, ...).InvokeIgnore(receiver)
end

function snet.InvokeServer(name, ...)
	return snet.Request(name, ...).InvokeServer()
end