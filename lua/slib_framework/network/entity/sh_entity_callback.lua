local snet = snet
local table = table
local IsValid = IsValid
local SERVER = SERVER
local ipairs = ipairs
local hook = hook
local AddOriginToPVS = AddOriginToPVS
local RealTime = RealTime
local isentity = isentity
local unpack = unpack
--

if SERVER then
	local entities_queue = {}

	local function entities_pack(tbl, data)
		for i = 1, #data do
			local value = data[i]
			if isentity(value) and IsValid(value) then
				table.insert(tbl, value)
			elseif type(value) == 'table' then
				entities_pack(tbl, value)
			end
		end
	end

	snet.Callback('snet_sv_entity_network_start', function(ply, id, backward)
		local request = snet.FindRequestById(id, true)
		if not request then return end

		local entities = {}
		entities_pack(entities, request.data)

		if #entities == 0 then return end

		table.insert(entities_queue, {
			id = id,
			backward = backward or false,
			request_data = {
				id = request.id,
				name = request.name,
				vars = request.data,
				unreliable = request.unreliable,
				func_success = request.func_success
			},
			ply = ply,
			entities = entities,
			equalDelay = 0,
			timeout = RealTime() + 5,
			isSuccess = false,
		})
	end)

	snet.Callback('snet_sv_entity_network_success', function(ply, id)
		for _, data in ipairs(entities_queue) do
			if not data.isSuccess and data.id == id then
				snet.Create('snet_cl_entity_network_success', id).Invoke(ply)
				data.isSuccess = true
				return
			end
		end
	end)

	hook.Add('SetupPlayerVisibility', 'Slib_TemporaryEntityNetworkVisibility', function(ply)
		for _, data in ipairs(entities_queue) do
			for i = 1, #data.entities do
				local ent = data.entities[i]
				if IsValid(ent) and data.ply == ply then
					AddOriginToPVS(ent:GetPos())
				end
			end
		end
	end)

	hook.Add('Tick', 'Slib_TemporaryEntityNetworkVisibilityChecker', function()
		local delay_infelicity = 0

		for i = #entities_queue, 1, -1 do
			local data = entities_queue[i]
			local request_data = data.request_data
			local ply = data.ply
			local backward = data.backward
			local entities = {}
			local real_time = RealTime()

			for k = 1, #data.entities do
				local ent = data.entities[k]
				if IsValid(ent) then
					table.insert(entities, ent)
				end
			end

			if data.timeout < real_time or #entities == 0 or not IsValid(ply) then
				hook.Run('SNetEntitySuccessInvoked', false, request_data.name, ply, entities)
				table.remove(entities_queue, i)
			elseif data.isSuccess then
				hook.Run('SNetEntitySuccessInvoked', true, request_data.name, ply, entities)
				table.remove(entities_queue, i)
			elseif data.equalDelay < real_time then
				snet.Create('snet_cl_entity_network_callback',
					request_data.id, request_data.name, request_data.vars, backward)
					.Success(request_data.func_success)
					.Error(request_data.func_error)
					.Invoke(ply)

				data.equalDelay = real_time + 0.5 + delay_infelicity
				delay_infelicity = delay_infelicity + 0.1
			end
		end
	end)
else
	local uids_block = {}

	snet.Callback('snet_cl_entity_network_callback', function(ply, id, name, vars, backward)
		for i = 1, #vars do
			local ent = vars[i]
			if isentity(ent) and ( not IsValid(ent) or table.HasValueBySeq(uids_block, id) ) then
				return
			end
		end

		snet.Create('snet_sv_entity_network_success', id).InvokeServer()
		table.insert(uids_block, id)

		snet.execute(backward, id, name, ply, unpack(vars))
	end)

	snet.Callback('snet_cl_entity_network_success', function(_, uid)
		table.RemoveByValue(uids_block, uid)
	end)

	SNET_ENTITY_VALIDATOR = function(backward, id, name, ply, ...)
		local args = { ... }
		if #args == 0 then return end

		for i = 1, #args do
			local ent = args[i]
			if isentity(ent) and not IsValid(ent) then
				snet.Create('snet_sv_entity_network_start', id, backward).InvokeServer()
				return false
			end
		end
	end
end