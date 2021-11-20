local slib = slib
local snet = slib.Components.Network
local net = net
local table = table
local player = player
local CLIENT = CLIENT
local SERVER = SERVER
local MsgN = MsgN
local istable = istable
local isstring =  isstring
local isfunction = isfunction
local RealTime = RealTime
local xpcall = xpcall
local snet_Serialize = snet.Serialize
local util_Compress = util.Compress
--
local REQUEST_LIFE_TIME = snet.REQUEST_LIFE_TIME
local request_storage = {}

function snet.Request(name, ...)
	local obj = {}
	obj.id = slib.GenerateUid(name)
	obj.name = name
	obj.data = { ... }
	obj.compressed_data = util_Compress(snet_Serialize(obj.data, true))
	if not obj.compressed_data then
		obj.compressed_data = util_Compress(snet_Serialize())
		MsgN('[SNET ERROR] An error occurred while compressing data - ' .. name)
	end
	obj.compressed_length = #obj.compressed_data
	obj.bigdata = nil
	obj.backward = false
	obj.func_success = nil
	obj.func_error = nil
	obj.func_complete = nil
	obj.lifetime = REQUEST_LIFE_TIME
	obj.receiver = {}
	obj.receiver_count = 1
	obj.receiver_complete_count = 0

	function obj.BigData(data, max_size, progress_text)
		if not istable(data) and not isstring(data) then return end

		obj.bigdata = {
			data = data,
			max_size = max_size,
			progress_text = progress_text
		}

		return obj
	end

	function obj.SetLifeTime(time)
		obj.lifetime = time
		return obj
	end

	function obj.Success(func)
		if func and isfunction(func) then
			obj.func_success = func
			obj.backward = true
		end
		return obj
	end

	function obj.Error(func)
		if func and isfunction(func) then
			obj.func_error = func
			obj.backward = true
		end
		return obj
	end

	function obj.Complete(func)
		if func and isfunction(func) then
			obj.func_complete = func
			obj.backward = true
		end
		return obj
	end

	function obj.Eternal()
		obj.eternal = true
	end

	function obj.Invoke(receiver, unreliable)
		if CLIENT then return end

		if not istable(receiver) then
			receiver = { receiver }
		end

		receiver = slib.ListFastPlayerParse(receiver)

		obj.receiver_count = #receiver
		obj.receiver = receiver

		local bigdata = obj.bigdata
		if bigdata then
			for i = 1, #receiver do
				snet.InvokeBigData(obj, receiver[i], bigdata.data, bigdata.max_size, bigdata.progress_text)
			end
			return obj
		end

		snet.AddRequestToList(obj)
		unreliable = unreliable or false

		net.Start('cl_network_rpc_callback', unreliable)
		net.WriteString(obj.id)
		net.WriteString(obj.name)
		net.WriteUInt(obj.compressed_length, 32)
		net.WriteData(obj.compressed_data, obj.compressed_length)
		net.WriteBool(obj.backward)
		net.Send(receiver)
		return obj
	end

	function obj.InvokeAll(unreliable)
		if CLIENT then return end
		obj.Invoke(player.GetHumans(), unreliable)
		return obj
	end

	function obj.InvokeIgnore(receiver, unreliable)
		if CLIENT then return end
		local receivers = {}

		if isentity(receiver) then
			table.insert(receivers, receiver)
		end

		if #receivers == 0 then
			obj.Invoke(player.GetHumans(), unreliable)
		else
			local players = player.GetHumans()
			local player_list = {}
			for i = 1, #players do
				local ply = players[i]
				if not table.HasValueBySeq(receivers, ply) then
					table.insert(player_list, ply)
				end
			end
			obj.Invoke(player_list, unreliable)
		end

		return obj
	end

	function obj.InvokeServer(unreliable)
		if SERVER then return end
		local bigdata = obj.bigdata
		if bigdata then
			snet.InvokeBigData(obj, nil, bigdata.data, bigdata.max_size, bigdata.progress_text)
			return
		end

		snet.AddRequestToList(obj)
		unreliable = unreliable or false

		net.Start('sv_network_rpc_callback', unreliable)
		net.WriteString(obj.id)
		net.WriteString(obj.name)
		net.WriteUInt(obj.compressed_length, 32)
		net.WriteData(obj.compressed_data, obj.compressed_length)
		net.WriteBool(obj.backward)
		net.SendToServer()
		return obj
	end

	function obj:Clone()
		local clone = snet.Request(obj.name)
		clone.data = obj.data
		clone.compressed_data = obj.compressed_data
		clone.compressed_length = obj.compressed_length
		clone.bigdata = obj.bigdata
		clone.backward = obj.backward
		clone.func_success = obj.func_success
		clone.func_error = obj.func_error
		clone.lifetime = obj.lifetime
		return clone
	end

	return obj
end

function snet.AddRequestToList(request)
	table.insert(request_storage, {
		request = request,
		timeout = RealTime() + (request.lifetime or REQUEST_LIFE_TIME)
	})
end

function snet.GetRequestList()
	return request_storage
end


function snet.FindRequestById(id, to_extend)
	to_extend = to_extend or false

	for i = #request_storage, 1, -1 do
		local data = request_storage[i]
		if data and data.request and data.request.id == id then
			if to_extend then data.timeout = RealTime() + data.request.lifetime end
			return data.request
		end
	end
	return nil
end

function snet.RemoveRequestById(id)
	for i = #request_storage, 1, -1 do
		local data = request_storage[i]
		if data and data.request and data.request.id == id then
			table.remove(request_storage, i)
			return true
		end
	end
	return false
end

timer.Create('SNet_AutoResetRequestAfterTimeDealy', 1, 0, function()
	xpcall(function()
		local counting_requests = {}

		for i = #request_storage, 1, -1 do
			local data = request_storage[i]
			if not data or (data.request and not data.request.eternal and data.timeout < RealTime()) then
				if data and data.request and data.request.func_complete then
					xpcall(function()
						data.request.func_complete(data.receiver, data)
					end, function(error_message)
						slib.Error('Failed to complete the request due to an error')
						slib.Error('NETWORK ERROR:\n' .. error_message)
					end)
				end
				table.remove(request_storage, i)
			end

			if data and data.request then
				local request_name = data.request.name
				counting_requests[request_name] = counting_requests[request_name] or 0
				counting_requests[request_name] = counting_requests[request_name] + 1
			end
		end

		local count = #request_storage
		if count >= 500 then
			slib.Warning('Something is making too many requests (' .. count .. ')')
			for k, v in pairs(counting_requests) do
				slib.Warning('COUNTING REQUEST: ' .. k .. ' - ' .. v)
			end
		end
	end, function(error_message)
		slib.Error('Attention! Something is creating errors in the request queue!'
			.. ' Contact the developer to identify issues.')
		slib.Error('NETWORK ERROR: ' .. error_message)
	end)
end)