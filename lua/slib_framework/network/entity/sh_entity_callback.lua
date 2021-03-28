local sv_net_result_name = slib.AddNetworkString('snet', 'sv_entity_network_result')
local cl_net_callback_name = slib.AddNetworkString('snet', 'cl_entity_network_callback')

if CLIENT then
	snet.RegisterCallback(cl_net_callback_name, function(_, name, uid, ent, vars)
		if snet.storage.default[name] == nil then return end
		
		if not IsValid(ent) then
			snet.Invoke(sv_net_result_name, uid, false)
			return
		end

		snet.Invoke(sv_net_result_name, uid, true)
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

snet.RegisterCallback(sv_net_result_name, function(ply, uid, success)
	for _, data in ipairs(entities_queue) do
		if data.uid == uid then
			data.isSuccess = success
			hook.Run('Slib_InvokeEntitySuccess', ply, data.ent, unpack(data.args))
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

hook.Add('Tick', 'Slib_TemporaryEntityNetworkVisibilityChecker', function()
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

					snet.Invoke(cl_net_callback_name, ply, name, data.uid, data.ent, data.args)
					
					data.equalDelay = RealTime() + 1.5 + delay_infelicity
					delay_infelicity = delay_infelicity + 0.1
				end
			end
		end
	end
end)