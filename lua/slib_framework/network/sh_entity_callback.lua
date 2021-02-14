local entities_queue = {}
local storage = {}

if SERVER then
	util.AddNetworkString('sv_entity_network_rpc_result')
	util.AddNetworkString('cl_entity_network_rpc_callback')
else
	snet.Receive('cl_entity_network_rpc_callback', function(len, ply)
		if CLIENT then
			ply = LocalPlayer()
		end
	
		local name = net.ReadString()
		local uid = net.ReadString()
	
		if storage[name] ~= nil then
			local ent = net.ReadEntity()
			if not IsValid(ent) then
				net.Start('sv_entity_network_rpc_result')
				net.WriteString(name)
				net.WriteString(uid)
				net.WriteBool(false)
				net.SendToServer()
				return
			end

			local data = storage[name]
	
			if data.adminOnly then
				if ply:IsAdmin() or ply:IsSuperAdmin() then
					local vars = net.ReadType()
					data.execute(ply, ent, unpack(vars))
				end
			else
				local vars = net.ReadType()
				data.execute(ply, ent, unpack(vars))
			end
	
			if data.onRemove then
				net.RemoveCallback(name)
			end
	
			net.Start('sv_entity_network_rpc_result')
			net.WriteString(name)
			net.WriteString(uid)
			net.WriteBool(true)
			net.SendToServer()
		end
	end)
end

if SERVER then
	snet.EntityInvoke = function(name, ply, ent, ...)
		if not IsValid(ent) then return end
		if not IsValid(ply) or not ply:IsPlayer() then return end
		
		for _, v in ipairs(entities_queue) do
			if v.name == name and v.ply == ply and v.ent == ent then
				return
			end
		end

		table.insert(entities_queue, {
			uid = ply:UserID() .. ent:EntIndex() .. tostring(RealTime()) .. tostring(SysTime()),
			name = name,
			ply = ply,
			ent = ent,
			args = { ... },
			equalDelay = 0,
			isSuccess = false,
		})
	end

	snet.EntityInvokeAll = function(name, ent, ...)
		for _, ply in ipairs(player.GetAll()) do
			if IsValid(ply) then
				snet.EntityInvoke(name, ply, ent, ...)
			end
		end
	end

	net.Receive('sv_entity_network_rpc_result', function(len, ply)
		local name = net.ReadString()
		local uid = net.ReadString()
		local success = net.ReadBool()

		if success then
			for _, data in ipairs(entities_queue) do
				if data.uid == uid then
					data.isSuccess = true
					return
				end
			end
		end
	end)

	hook.Add('SetupPlayerVisibility', 'Slib_TemporaryEntityNetworkVisibility', function(ply, ent)
		for _, data in ipairs(entities_queue) do
			if data.ply == ply and data.ent == ent then
				AddOriginToPVS(ent:GetPos())
			end
		end
	end)
	
	hook.Add('Think', 'Slib_TemporaryEntityNetworkVisibilityChecker', function()
		for i = #entities_queue, 1, -1 do
			local data = entities_queue[i]
			local name = data.name
			local ply = data.ply
			local ent = data.ent

			if not IsValid(ent) or not IsValid(ply) then
				hook.Run('SlibEntitySuccessInvoked', false, name, ply, ent)
				table.remove(entities_queue, i)
			else	
				if data.isSuccess then
					hook.Run('SlibEntitySuccessInvoked', true, name, ply, ent)
					table.remove(entities_queue, i)
				else
					if data.equalDelay < RealTime() then
						net.Start('cl_entity_network_rpc_callback')
						net.WriteString(name)
						net.WriteString(data.uid)
						net.WriteEntity(data.ent)
						net.WriteType(data.args)
						net.Send(ply)
						
						data.equalDelay = RealTime() + 0.5
					end
				end
			end
		end
	end)
else
	snet.RegisterEntityCallback = function(name, func, onRemove, adminOnly)
		adminOnly = adminOnly or false
		onRemove = onRemove or false
		storage[name] = {
			adminOnly = adminOnly,
			execute = func,
			onRemove = onRemove
		}
	end

	snet.RemoveEntityCallback = function(name)
		storage[name] = nil
	end
end