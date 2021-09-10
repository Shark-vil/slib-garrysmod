local snet = snet
local CLIENT = CLIENT
--

function snet.Invoke(name, receiver, ...)
	if CLIENT then
		return snet.Create(name, ...).InvokeServer()
	end
	return snet.Create(name, ...).Invoke(receiver)
end

function snet.InvokeAll(name, ...)
	return snet.Create(name, ...).InvokeAll()
end

function snet.InvokeIgnore(name, receiver, ...)
	return snet.Create(name, ...).InvokeIgnore(receiver)
end

function snet.InvokeServer(name, ...)
	return snet.Create(name, ...).InvokeServer()
end