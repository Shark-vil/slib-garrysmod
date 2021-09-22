local net = net
local snet = slib.Components.Network
local hook = hook
--

-- Called when the client requests a new batch of data
-- CLIENT (slib_cl_bigdata_receive / slib_cl_bigdata_processing) --> SERVER
net.Receive('slib_sv_bigdata_receive_ok', function(len, ply)
	local name = net.ReadString()
	local index = net.ReadInt(10)
	local data = slib.Storage.Network.bigdata[index]
	if data == nil or data.ply ~= ply then return end

	data.current_part = data.current_part + 1
	local part = data.net_parts[data.current_part]
	net.Start('slib_cl_bigdata_processing')
	net.WriteString(name)
	net.WriteInt(index, 10)
	net.WriteInt(data.current_part, 10)
	net.WriteUInt(part.length, 24)
	net.WriteData(part.data, part.length)
	net.Send(ply)

	if data.current_part >= data.max_parts then
		local request = snet.FindRequestById(data.id)
		if request then
			if request.func_success then
				request.func_success(ply, request)
			end

			request.receiver_complete_count = request.receiver_complete_count + 1
			if request.receiver_complete_count >= request.receiver_count then
				if request.func_complete then
					request.func_complete(request.receiver, request)
				end
				snet.RemoveRequestById(data.id)
			end
		end

		hook.Run('SnetBigDataFinished', ply, name, data)
		slib.Storage.Network.bigdata[index] = nil
	end
end)

-- Executed once if the client rejects the request.
-- CLIENT (slib_cl_bigdata_receive) --> SERVER
net.Receive('slib_sv_bigdata_receive_error', function(len, ply)
	local name = net.ReadString()
	local index = net.ReadInt(10)
	local data = slib.Storage.Network.bigdata[index]

	if data == nil or data.ply ~= ply then return end

	local request = snet.FindRequestById(data.id)
	if request then
		if request.func_error then
			request.func_error(ply, request)
		end

		request.receiver_count = request.receiver_count - 1
		if request.receiver_complete_count >= request.receiver_count then
			if request.func_complete then
				request.func_complete()
			end
			snet.RemoveRequestById(data.id)
		end
	end

	hook.Run('SnetBigDataFailed', ply, name, data)
	slib.Storage.Network.bigdata[index] = nil
end)