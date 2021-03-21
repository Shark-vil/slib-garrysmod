local entities_queue = {}

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
	
		if snet.storage[name] == nil then return end
		
		local ent = net.ReadEntity()
		if not IsValid(ent) then
			net.Start('sv_entity_network_rpc_result')
			net.WriteString(uid)
			net.WriteBool(false)
			net.SendToServer()
			return
		end

		net.Start('sv_entity_network_rpc_result')
		net.WriteString(uid)
		net.WriteBool(true)
		net.SendToServer()

		local vars = net.ReadTable()
		snet.execute(name, ply, ent, unpack(vars))
	end)
end

if SERVER then
	snet.EntityInvoke = function(name, ply, ent, ...)
		if not IsValid(ent) then return end
		if not IsValid(ply) or not ply.slibIsSpawn then return end
		
		-- for _, v in ipairs(entities_queue) do
		-- 	if v.name == name and v.ply == ply and v.ent == ent then
		-- 		return
		-- 	end
		-- end

		table.insert(entities_queue, {
			uid = ply:UserID() .. ent:EntIndex() .. tostring(RealTime()) .. tostring(SysTime()),
			name = name,
			ply = ply,
			ent = ent,
			args = { ... },
			equalDelay = 0,
			isSuccess = false,
			-- isAnswer = true,
		})
	end

	snet.EntityInvokeAll = function(name, ent, ...)
		for _, ply in ipairs(slib.GetAllLoadedPlayers()) do
			if IsValid(ply) and IsValid(ent) then
				snet.EntityInvoke(name, ply, ent, ...)
			end
		end
	end

	net.Receive('sv_entity_network_rpc_result', function(len, ply)
		local uid = net.ReadString()
		local success = net.ReadBool()

		for _, data in ipairs(entities_queue) do
			if data.uid == uid then
				data.isSuccess = success
				-- data.isAnswer = true
				return
			end
		end
	end)

	hook.Add('SetupPlayerVisibility', 'Slib_TemporaryEntityNetworkVisibility', function(ply, ent)
		for _, data in ipairs(entities_queue) do
			if IsValid(data.ent) and data.ply == ply then
				AddOriginToPVS(data.ent:GetPos())
			end
		end
	end)
	
	hook.Add('Think', 'Slib_TemporaryEntityNetworkVisibilityChecker', function()
		local delay_infelicity = 0

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
						-- data.isAnswer = false

						net.Start('cl_entity_network_rpc_callback')
						net.WriteString(name)
						net.WriteString(data.uid)
						net.WriteEntity(data.ent)
						net.WriteTable(data.args)
						net.Send(ply)
						
						data.equalDelay = RealTime() + 1.5 + delay_infelicity
						delay_infelicity = delay_infelicity + 0.1
					end
				end
			end
		end
	end)
else
	snet.RegisterEntityCallback = function(name, func, onRemove, adminOnly)
		adminOnly = adminOnly or false
		onRemove = onRemove or false
		snet.storage[name] = {
			adminOnly = adminOnly,
			execute = func,
			onRemove = onRemove
		}
	end

	snet.RemoveEntityCallback = function(name)
		snet.storage[name] = nil
	end
end