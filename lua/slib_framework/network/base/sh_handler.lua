local CLIENT = CLIENT
local SERVER = SERVER
local snet = snet
local table = table
local isbool = isbool
local RealTime = RealTime
local net = net
local hook = hook
local util = util
--
local REQUEST_LIMITS_LIST = snet.REQUEST_LIMITS_LIST

local function request_handler(backward, id, name, ply, ...)
	if CLIENT then ply = LocalPlayer() end

	local data = snet.GetCallback(name)
	if not data then return false end

	if data.isAdmin and (not ply:IsAdmin() and not ply:IsSuperAdmin()) then return false end

	if data.limits then
		local isExist = false

		for i = #REQUEST_LIMITS_LIST, 1, -1 do
			local value = REQUEST_LIMITS_LIST[i]
			if value and value.ply == ply and value.name == name then
				isExist = true

				if value.nextTime <= RealTime() then
					table.remove(REQUEST_LIMITS_LIST, i)
					break
				end

				if value.current == value.limit then
					value.warning(ply, name)
				else
					value.current = value.current + 1
				end

				value.nextTime = RealTime() + data.limits.delay
				return false
			end
		end

		if not isExist then
			table.insert(REQUEST_LIMITS_LIST, {
				ply = ply,
				name = name,
				nextTime = RealTime() + data.limits.delay,
				limit = data.limits.limit,
				current = 0,
				warning = data.limits.warning or function(ply, name)
					MsgN('Attention! An attempt to hack or disable '
					.. 'the server is possible! Player - "' .. tostring(ply)
					.. '" is sending too many validation checks on the hook "' .. name .. '"!')
				end
			})
		end
	end

	if data.validator then
		local validator_result = data.validator(backward, id, name, ply, ...)
		if isbool(validator_result) and not validator_result then return false end
	end

	data.execute(ply, ...)

	if data.auto_destroy then snet.RemoveCallback(name) end

	return true
end

function snet.execute(backward, id, name, ply, ...)
	local success = request_handler(backward, id, name, ply, ...)

	if backward then
		if CLIENT then
			if success then
				net.Start('sv_network_rpc_success')
			else
				net.Start('sv_network_rpc_error')
			end
			net.WriteString(id)
			net.SendToServer()
		else
			if success then
				net.Start('cl_network_rpc_success')
			else
				net.Start('cl_network_rpc_error')
			end
			net.WriteString(id)
			net.Send(ply)
		end
	end

	hook.Run('SNetRequestResult', id, name, reuslt, vars)
end

local function net_receive_base(len, ply)
	local id = net.ReadString()
	local name = net.ReadString()
	local compressed_length = net.ReadUInt(32)
	local compressed_data = net.ReadData(compressed_length)
	local backward = net.ReadBool()
	local vars = snet.Deserialize(util.Decompress(compressed_data))
	snet.execute(backward, id, name, ply, unpack(vars))
end

if SERVER then
	net.Receive('sv_network_rpc_callback', net_receive_base)
else
	net.Receive('cl_network_rpc_callback', net_receive_base)
end