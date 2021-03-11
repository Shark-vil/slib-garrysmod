function snet.execute(name, ply, ...)
	if CLIENT then ply = LocalPlayer() end

	if snet.storage[name] == nil then return end

	local data = snet.storage[name]

	if data.adminOnly then
		if ply:IsAdmin() or ply:IsSuperAdmin() then
			data.execute(ply, ...)
		end
	else
		data.execute(ply, ...)
	end

	if data.onRemove then
		net.RemoveCallback(name)
	end
end

local function network_callback(len, ply)
	local name = net.ReadString()
	local vars = net.ReadType()

	snet.execute(name, ply, unpack(vars))
end

if SERVER then
	util.AddNetworkString('sv_network_rpc_callback')
	util.AddNetworkString('cl_network_rpc_callback')

	snet.Receive('sv_network_rpc_callback', network_callback)
else
	snet.Receive('cl_network_rpc_callback', network_callback)
end

snet.Invoke = function(name, ply, ...)
	if SERVER then
		if not IsValid(ply) or not ply:IsPlayer() then return end
		
		net.Start('cl_network_rpc_callback')
		net.WriteString(name)
		net.WriteType({ ... })
		net.Send(ply)
	else
		net.Start('sv_network_rpc_callback')
		net.WriteString(name)
		net.WriteType({ ... })
		net.SendToServer()
	end
end

snet.InvokeAll = function(name, ...)
	if SERVER then
		net.Start('cl_network_rpc_callback')
		net.WriteString(name)
		net.WriteType({ ... })
		net.Broadcast()
	end
end

snet.RegisterCallback = function(name, func, onRemove, adminOnly)
	adminOnly = adminOnly or false
	onRemove = onRemove or false
	snet.storage[name] = {
		adminOnly = adminOnly,
		execute = func,
		onRemove = onRemove
	}
end

snet.RemoveCallback = function(name)
	snet.storage[name] = nil
end