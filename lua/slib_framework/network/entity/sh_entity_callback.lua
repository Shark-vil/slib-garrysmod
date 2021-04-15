if SERVER then
	local entities_queue = {}

	snet.Callback('snet_sv_entity_network_start', function(ply, id)
		local request = snet.FindRequestById(id, true)
		if not request then return end

		local ent = request.data[1]
		if not ent or not IsValid(ent) then return end

		table.insert(entities_queue, {
			id = id,
			requestData = {
				id = request.id,
				name = request.name,
				vars = request.data,
				unreliable = request.unreliable,
				func_success = request.func_success
			},
			ply = ply,
			ent = ent,
			equalDelay = 0,
			timeout = RealTime() + 30,
			isSuccess = false,
		})
	end).Register()

	snet.Callback('snet_sv_entity_network_success', function(ply, id)
		for _, data in ipairs(entities_queue) do
			if not data.isSuccess and data.id == id then
				snet.Create('snet_cl_entity_network_success', id).Invoke(ply)
				data.isSuccess = true
				return
			end
		end
	end).Register()

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
			local requestData = data.requestData
			local ply = data.ply
			local ent = data.ent
			local real_time = RealTime()

			if data.timeout < real_time or not IsValid(ent) or not IsValid(ply) then
				hook.Run('SNetEntitySuccessInvoked', false, requestData.name, ply, ent)
				table.remove(entities_queue, i)
			elseif data.isSuccess then
				hook.Run('SNetEntitySuccessInvoked', true, requestData.name, ply, ent)
				table.remove(entities_queue, i)
			elseif data.equalDelay < real_time then
				snet.Create('snet_cl_entity_network_callback', requestData.id, requestData.name, requestData.vars)
					.Success(requestData.func_success)
					.Error(requestData.func_error)
					.Invoke(ply)

				data.equalDelay = real_time + 0.5 + delay_infelicity
				delay_infelicity = delay_infelicity + 0.1
			end
		end
	end)
else
	local uids_block = {}
	
	snet.Callback('snet_cl_entity_network_callback', function(ply, id, name, vars)
		local ent = vars[1]

		if not ent or not isentity(ent) or not IsValid(ent) then return end
		if array.HasValue(uids_block, id) then return end

		snet.Create('snet_sv_entity_network_success', id).InvokeServer()
		table.insert(uids_block, id)

		snet.execute(id, name, ply, false, unpack(vars))
	end).Register()

	snet.Callback('snet_cl_entity_network_success', function(_, uid)
		table.RemoveByValue(uids_block, uid)
	end).Register()

	SNET_ENTITY_VALIDATOR = function(id, name, ply, ent)
		if not ent or not isentity(ent) then return end
		if not IsValid(ent) then
			snet.Create('snet_sv_entity_network_start', id).InvokeServer()
			return false
		end
	end
end