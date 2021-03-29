if CLIENT then
	snet.RegisterCallback('snet_cl_entity_network_callback', function(_, name, uid, ent)
		if not IsValid(ent) then return end
		snet.Invoke('snet_sv_entity_network_success', nil, uid)
	end)

	snet.RegisterCallback('snet_cl_entity_network_success', function(_, name, ent, vars)
		if snet.storage.default[name] == nil then return end
		snet.execute(name, LocalPlayer(), ent, unpack(vars))
	end)
end

if not SERVER then return end

local entities_queue = {}

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
		args = snet.GetNormalizeDataTable({ ... }),
		equalDelay = 0,
		isSuccess = false,
	})
end

snet.EntityInvokeAll = function(name, ent, ...)
	for _, ply in ipairs(slib.GetAllLoadedPlayers()) do
		if IsValid(ply) and IsValid(ent) then
			snet.EntityInvoke(name, ply, ent, ...)
		end
	end
end

snet.RegisterCallback('snet_sv_entity_network_success', function(ply, uid)
	for _, data in ipairs(entities_queue) do
		if not data.isSuccess and data.uid == uid then
			snet.Invoke('snet_cl_entity_network_success', ply, data.name, data.ent, data.args)
			data.isSuccess = true
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

hook.Add('Tick', 'Slib_TemporaryEntityNetworkVisibilityChecker', function()
	local delay_infelicity = 0

	for i = #entities_queue, 1, -1 do
		local data = entities_queue[i]
		local name = data.name
		local ply = data.ply
		local ent = data.ent

		if not IsValid(ent) or not IsValid(ply) then
			table.remove(entities_queue, i)
		elseif data.isSuccess then
			hook.Run('Slib_EntitySuccessInvoked', name, ply, ent)
			table.remove(entities_queue, i)
		elseif data.equalDelay < RealTime() then
			snet.Invoke('snet_cl_entity_network_callback', ply, name, data.uid, data.ent)
			data.equalDelay = RealTime() + 0.5 + delay_infelicity
			delay_infelicity = delay_infelicity + 0.1
		end
	end
end)