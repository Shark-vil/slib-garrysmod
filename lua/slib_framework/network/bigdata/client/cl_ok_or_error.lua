local net = net
local snet = snet
local notification = notification
local hook = hook
local LocalPlayer = LocalPlayer
--

-- Called when the server requests a new batch of data
-- SERVER (slib_sv_bigdata_receive / slib_sv_bigdata_processing) --> CLIENT
net.Receive('slib_cl_bigdata_receive_ok', function()
	local name = net.ReadString()
	local index = net.ReadInt(10)
	local data = snet.storage.bigdata[index]
	if data == nil then return end
	data.current_part = data.current_part + 1
	local part = data.net_parts[data.current_part]
	net.Start('slib_sv_bigdata_processing')
	net.WriteString(name)
	net.WriteInt(index, 10)
	net.WriteInt(data.current_part, 10)
	net.WriteUInt(part.length, 24)
	net.WriteData(part.data, part.length)
	net.SendToServer()

	if data.progress_id ~= '' and data.progress_text ~= '' then
		notification.AddProgress(data.progress_id, data.progress_text, (1 / data.max_parts) * data.current_part)
	end

	if data.current_part >= data.max_parts then
		if data.progress_id ~= '' and data.progress_text ~= '' then
			notification.Kill(data.progress_id)
			notification.AddLegacy('Success! ' .. data.progress_text, NOTIFY_GENERIC, 3)
		end

		local request = snet.FindRequestById(data.id)
		if request then
			if request.func_success then
				request.func_success(LocalPlayer(), request)
			end

			request.receiver_complete_count = request.receiver_complete_count + 1
			if request.receiver_complete_count >= request.receiver_count then
				if request.func_complete then
					request.func_complete()
				end
				snet.RemoveRequestById(data.id)
			end
		end

		hook.Run('SnetBigDataFinished', LocalPlayer(), name, data)
		snet.storage.bigdata[index] = nil
	end
end)

-- Executed once if the server rejects the request
-- SERVER (slib_sv_bigdata_receive) --> CLIENT
net.Receive('slib_cl_bigdata_receive_error', function(len)
	local name = net.ReadString()
	local index = net.ReadInt(10)
	local data = snet.storage.bigdata[index]

	if data == nil then return end

	if data.progress_id ~= '' and data.progress_text ~= '' then
		notification.AddLegacy('An error occurred while sending data!', NOTIFY_ERROR, 5)
	end

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

	hook.Run('SnetBigDataFailed', LocalPlayer(), name, data)
	snet.storage.bigdata[index] = nil
end)