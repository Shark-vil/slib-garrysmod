snet.storage.default = snet.storage.default or {}
snet.requests = snet.requests or {}

local REQUEST_LIFE_TIME = 10

function snet.ValueIsValid(value)
	if isfunction(value) then return false end
	if value == nil then return false end
	return true
end

function snet.GetNormalizeDataTable(data, entity_to_table)
	local entity_to_table = entity_to_table or false
	local new_data = {}

	if not istable(data) then return new_data end
	if data._snet_disable then return new_data end
	if data._get_snet_data and isfunction(data._get_snet_data) then return data:_get_snet_data() end

	for k, v in pairs(data) do
		if not snet.ValueIsValid(k) or not snet.ValueIsValid(v) then goto skip end

		if istable(v) then
			new_data[k] = snet.GetNormalizeDataTable(v, entity_to_table)
		elseif entity_to_table and isentity(v) then
			new_data[k] = snet.GetNormalizeDataTable(v:GetTable(), entity_to_table)
		else
			new_data[k] = v
		end

		::skip::
	end

	return new_data
end

function snet.execute(id, name, ply, ...)
	if CLIENT then ply = LocalPlayer() end

	if snet.storage.default[name] == nil then
		return false
	end

	local data = snet.storage.default[name]

	if data.isAdmin then
		if not ply:IsAdmin() and not ply:IsSuperAdmin() then
			return false
		end
	end

	if data.validaotr then
		local validator_result = data.validaotr(id, name, ply, ...)
		if isbool(validator_result) and not validator_result then
			return false
		end
	end

	data.execute(ply, ...)

	if data.autoRemove then
		net.RemoveCallback(name)
	end

	return true
end

local function network_callback(len, ply)
	local id = net.ReadString()
	local name = net.ReadString()
	local vars = net.ReadTable()
	local reuslt = snet.execute(id, name, ply, unpack(vars))
	hook.Run('SNetRequestResult', id, name, reuslt, vars)
end

if SERVER then
	util.AddNetworkString('sv_network_rpc_callback')
	util.AddNetworkString('cl_network_rpc_callback')

	snet.Receive('sv_network_rpc_callback', network_callback)
else
	snet.Receive('cl_network_rpc_callback', network_callback)
end

snet.Create = function(name, unreliable)
	local obj = {}
	obj.id = snet.GenerateRequestID()
	obj.name = name
	obj.data = {}
	obj.unreliable = unreliable or false

	function obj.SetData(...)
		obj.data = snet.GetNormalizeDataTable({ ... })
		return obj
	end

	function obj.AddValue(value)
		if not snet.ValueIsValid(value) then return end
		table.insert(obj.data, value)
		return obj
	end

	function obj.Invoke(receiver)
		if CLIENT then return end
		obj.AddRequestToList()

		net.Start('cl_network_rpc_callback', obj.unreliable)
		net.WriteString(obj.id)
		net.WriteString(obj.name)
		net.WriteTable(obj.data)
		net.Send(receiver)

		return obj
	end

	function obj.InvokeBigData(receiver, max_size, progress_text)
		if CLIENT then return end
		snet.InvokeBigData(obj.name, receiver, obj.data[1], max_size, progress_text)
		return obj
	end

	function obj.InvokeAll()
		if CLIENT then return end
		obj.AddRequestToList()

		net.Start('cl_network_rpc_callback', obj.unreliable)
		net.WriteString(obj.id)
		net.WriteString(obj.name)
		net.WriteTable(obj.data)
		net.Broadcast()

		return obj
	end

	function obj.InvokeIgnore(receiver)
		if CLIENT then return end
		obj.AddRequestToList()

		net.Start('cl_network_rpc_callback', obj.unreliable)
		net.WriteString(obj.id)
		net.WriteString(obj.name)
		net.WriteTable(obj.data)
		net.SendOmit(receiver)

		return obj
	end

	function obj.InvokeServer()
		if SERVER then return end
		obj.AddRequestToList()

		net.Start('sv_network_rpc_callback', obj.unreliable)
		net.WriteString(obj.id)
		net.WriteString(obj.name)
		net.WriteTable(obj.data)
		net.SendToServer()

		return obj
	end

	function obj.InvokeServerBigData(max_size, progress_text)
		if SERVER then return end
		snet.InvokeBigData(obj.name, nil, obj.data[1], max_size, progress_text)
		return obj
	end

	function obj.AddRequestToList()
		table.insert(snet.requests, {
			request = obj,
			resetTime = RealTime() + REQUEST_LIFE_TIME
		})

		return obj
	end

	return obj
end

local request_id = 0
local last_time_request_id_generate = -1
snet.GenerateRequestID = function()
	local time = RealTime()
	request_id = request_id + 1
	last_time_request_id_generate = time
	return tostring(util.CRC(time + request_id))
end

-- Reset unique request IDs if there is no activity for a long time.
timer.Create('SNet_RequestIdResetToZero', 1, 0, function()
	if last_time_request_id_generate == -1 then return end
	if last_time_request_id_generate + 60 < RealTime() then
		request_id = 0
		last_time_request_id_generate = -1
	end
end)

snet.FindRequestByID = function(id)
	for i = 1, #snet.requests do
		local data = snet.requests[i]
		if data.request and data.request.id == id then
			data.resetTime = RealTime() + REQUEST_LIFE_TIME
			return data.request
		end
	end
	return nil
end

snet.Callback = function(name, func)
	local obj = {}
	obj.name = name
	obj.execute = func
	obj.validator = nil
	obj.isAdmin = false
	obj.autoRemove = false

	function obj.Protect()
		obj.isAdmin = true
		return obj
	end

	function obj.Validator(func_validator)
		if not isfunction(func_validator) then return end
		obj.validator = func_validator
		return obj
	end

	function obj.AutoRemove()
		obj.autoRemove = true
		return obj
	end

	function obj.Register()
		snet.storage.default[name] = {
			execute = obj.execute,
			validaotr = obj.validator,
			isAdmin = obj.isAdmin,
			autoRemove = obj.autoRemove
		}
		return obj
	end

	return obj
end

-- Outdated method for backward compatibility
snet.RegisterCallback = function(name, func, autoremove, isadmin)
	local callback = snet.Callback(name, func)
	if autoremove then callback.AutoRemove() end
	if isadmin then callback.Protect() end
	callback.Register()
	return callback
end

snet.RemoveCallback = function(name)
	snet.storage.default[name] = nil
end

timer.Create('SNet_AutoResetRequestAfterTimeDealy', 1, 0, function()
	xpcall(function()
		for i = #snet.requests, 1, -1 do
			local data = snet.requests[i]
			if not data.request or data.resetTime < RealTime() then
				table.remove(snet.requests, i)
			end
		end
	end, function(error_message)
		print('Attention! Something is creating errors in the request queue!')
		print('Contact the developer to identify issues.')
		print('SLIB NETWORK ERROR: ' .. error_message)
	end)
end)