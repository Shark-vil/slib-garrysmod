local net = net
local snet = slib.Components.Network
local LocalPlayer = LocalPlayer
local hook = hook
local notification = notification
local util = util
--
local processing_data = {}

-- Executed for the first time before data processing
-- SERVER (sh_callback_bigdata.lua) --> CLIENT
net.Receive('slib_cl_bigdata_receive', function()
	local ply = LocalPlayer()
	local name = net.ReadString()
	local is_error = false
	local callback = snet.GetCallback(name)

	if not callback then
		is_error = true
	elseif callback.isAdmin then
		if not ply:IsAdmin() and not ply:IsSuperAdmin() then
			is_error = true
		end
	end

	local index = net.ReadInt(32)

	if is_error then
		net.Start('slib_sv_bigdata_receive_error')
		net.WriteString(name)
		net.WriteInt(index, 32)
		net.SendToServer()

		return
	end

	local max_parts = net.ReadInt(32)
	local progress_id = net.ReadString()
	local progress_text = net.ReadString()

	processing_data[index] = {
		max_parts = max_parts,
		current_part = 0,
		parts_data = {},
		progress_id = progress_id,
		progress_text = progress_text,
	}

	net.Start('slib_sv_bigdata_receive_ok')
	net.WriteString(name)
	net.WriteInt(index, 32)
	net.SendToServer()
end)

-- Called every time a new batch of data is received from the server
-- SERVER (slib_sv_bigdata_receive_ok) --> CLIENT
net.Receive('slib_cl_bigdata_processing', function(len)
	local ply = LocalPlayer()
	local name = net.ReadString()
	local index = net.ReadInt(32)
	local callback = snet.GetCallback(name)

	if not callback then return end
	if processing_data[index] == nil then return end

	local current_part = net.ReadInt(32)
	local compressed_length = net.ReadUInt(32)
	local compressed_data = net.ReadData(compressed_length)
	local data = processing_data[index]
	data.current_part = current_part
	table.insert(data.parts_data, compressed_data)

	if data.current_part == 1 then
		hook.Run('SnetBigDataStartSending', ply, name)
	end

	if data.progress_id ~= '' and data.progress_text ~= '' then
		notification.AddProgress(data.progress_id, data.progress_text, (1 / data.max_parts) * data.current_part)
	end

	if data.current_part >= data.max_parts then
		local data_string = ''

		for _, data_value in ipairs(data.parts_data) do
			data_string = data_string .. util.Decompress(data_value)
		end

		if data.progress_id ~= '' and data.progress_text ~= '' then
			notification.Kill(data.progress_id)
			notification.AddLegacy('Success! ' .. data.progress_text, NOTIFY_GENERIC, 3)
		end

		processing_data[index] = nil

		local result_data = util.JSONToTable(data_string)

		if not result_data then
			ErrorNoHalt('[SLIB.ERROR] Failed to convert ' .. name .. ' big data to JSON.')
			return
		end

		if result_data.data_type == 'table' then
			snet.execute(result_data.backward, result_data.id, name, ply, util.JSONToTable(result_data.data))
		elseif result_data.data_type == 'string' then
			snet.execute(result_data.backward, result_data.id, name, ply, result_data.data)
		end
	else
		net.Start('slib_sv_bigdata_receive_ok')
		net.WriteString(name)
		net.WriteInt(index, 32)
		net.SendToServer()
	end
end)