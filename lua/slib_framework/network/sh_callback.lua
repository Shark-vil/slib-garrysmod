snet.storage.default = snet.storage.default or {}
snet.requests = snet.requests or {}

local REQUEST_LIFE_TIME = 2
local REQUEST_LIMITS_LIST = {}

function snet.execute(id, name, ply, ...)
	if CLIENT then ply = LocalPlayer() end

	local data = snet.storage.default[name]
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
			array.insert(REQUEST_LIMITS_LIST, {
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
		local validator_result = data.validator(id, name, ply, ...)
		if isbool(validator_result) and not validator_result then return false end
	end

	data.execute(ply, ...)

	if data.autoRemove then net.RemoveCallback(name) end

	return true
end

local function network_callback(len, ply)
	local id = net.ReadString()
	local name = net.ReadString()
	local compressed_length = net.ReadUInt(32)
	local compressed_data = net.ReadData(compressed_length)
	local backward = net.ReadBool()
	local vars = snet.Deserialize(util.Decompress(compressed_data))
	local reuslt = snet.execute(id, name, ply, unpack(vars))

	if backward then
		if CLIENT then
			if reuslt then
				net.Start('sv_network_rpc_success')
			else
				net.Start('sv_network_rpc_error')
			end
			net.WriteString(id)
			net.SendToServer()
		else
			if reuslt then
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

if SERVER then
	util.AddNetworkString('sv_network_rpc_callback')
	util.AddNetworkString('cl_network_rpc_callback')
	util.AddNetworkString('sv_network_rpc_success')
	util.AddNetworkString('cl_network_rpc_success')
	util.AddNetworkString('sv_network_rpc_error')
	util.AddNetworkString('cl_network_rpc_error')

	snet.Receive('sv_network_rpc_callback', network_callback)

	-- Success result
	snet.Receive('sv_network_rpc_success', function(len, ply)
		local id = net.ReadString()
		local request = snet.FindRequestById(id)
		if not request or not request.func_success then return end
		request.func_success(ply, request)
		snet.RemoveRequestById(id)
	end)

	-- Error result
	snet.Receive('sv_network_rpc_error', function(len, ply)
		local id = net.ReadString()
		local request = snet.FindRequestById(id)
		if not request or not request.func_error then return end
		request.func_error(ply, request)
	end)
else
	snet.Receive('cl_network_rpc_callback', network_callback)

	-- Success result
	snet.Receive('cl_network_rpc_success', function(len, ply)
		local id = net.ReadString()
		local request = snet.FindRequestById(id)
		if not request or not request.func_success then return end
		request.func_success(LocalPlayer(), request)
		snet.RemoveRequestById(id)
	end)

	-- Error result
	snet.Receive('cl_network_rpc_error', function(len, ply)
		local id = net.ReadString()
		local request = snet.FindRequestById(id)
		if not request or not request.func_error then return end
		request.func_error(LocalPlayer(), request)
	end)
end

local function AddRequestToList(request)
	array.insert(snet.requests, {
		request = request,
		resetTime = RealTime() + (request.lifetime or REQUEST_LIFE_TIME)
	})
end

snet.Create = function(name, ...)
	local obj = {}
	obj.id = slib.GenerateUid(name)
	obj.name = name
	obj.data = { ... }
	obj.compressed_data = util.Compress(snet.Serialize(obj.data, false, true))
	if not obj.compressed_data then
		obj.compressed_data = util.Compress(snet.Serialize())
		MsgN('[SNET ERROR] An error occurred while compressing data - ' .. name)
	end
	obj.compressed_length = #obj.compressed_data
	obj.bigdata = nil
	obj.backward = false
	obj.func_success = nil
	obj.func_error = nil
	obj.lifetime = REQUEST_LIFE_TIME

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

	function obj.Invoke(receiver, unreliable)
		if CLIENT then return end

		if istable(receiver) then
			for i = 1, #receiver do obj.Clone().Invoke(receiver[i]) end
			return obj
		end

		local bigdata = obj.bigdata
		if bigdata then
			snet.InvokeBigData(obj.name, receiver, bigdata.data, bigdata.max_size, bigdata.progress_text)
			return obj
		end

		AddRequestToList(obj)
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
		obj.Invoke(slib.GetAllLoadedPlayers(), unreliable)
		return obj
	end

	function obj.InvokeIgnore(receiver, unreliable)
		if CLIENT then return end
		local receivers = {}

		if isentity(receiver) then
			array.insert(receivers, receiver)
		end

		if #receivers == 0 then
			obj.Invoke(slib.GetAllLoadedPlayers(), unreliable)
		else
			for _, ply in ipairs(slib.GetAllLoadedPlayers()) do
				if not array.HasValue(receivers, ply) then
					obj.Clone().Invoke(ply, unreliable)
				end
			end
		end

		return obj
	end

	function obj.InvokeServer(unreliable)
		if SERVER then return end
		local bigdata = obj.bigdata
		if bigdata then
			snet.InvokeBigData(obj.name, nil, bigdata.data, bigdata.max_size, bigdata.progress_text)
			return
		end

		AddRequestToList(obj)
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
		local clone = snet.Create(obj.name)
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

snet.Invoke = function(name, receiver, ...)
	if CLIENT then
		return snet.Create(name, ...).InvokeServer()
	end
	return snet.Create(name, ...).Invoke(receiver)
end

snet.InvokeAll = function(name, ...)
	return snet.Create(name, ...).InvokeAll()
end

snet.InvokeIgnore = function(name, receiver, ...)
	return snet.Create(name, ...).InvokeIgnore(receiver)
end

snet.InvokeServer = function(name, ...)
	return snet.Create(name, ...).InvokeServer()
end

snet.FindRequestById = function(id, to_extend)
	to_extend = to_extend or false

	for i = #snet.requests, 1, -1 do
		local data = snet.requests[i]
		if data and data.request and data.request.id == id then
			if to_extend then data.resetTime = RealTime() + data.request.lifetime end
			return data.request
		end
	end
	return nil
end

snet.RemoveRequestById = function(id)
	for i = #snet.requests, 1, -1 do
		local data = snet.requests[i]
		if data and data.request and data.request.id == id then
			table.remove(snet.requests, i)
			return true
		end
	end
	return false
end

snet.Callback = function(name, func)
	local private = {}
	private.name = name

	function private.SetParam(key, value)
		snet.storage.default[private.name] = snet.storage.default[private.name] or {}
		snet.storage.default[private.name][key] = value
	end

	local obj = {}
	private.SetParam('execute', func)

	function obj.Protect()
		private.SetParam('isAdmin', true)
		return obj
	end

	function obj.Validator(func_validator)
		assert(isfunction(func_validator), 'The variable "func_validator" must be a function!')
		private.SetParam('validator', func_validator)
		return obj
	end

	function obj.AutoRemove()
		private.SetParam('autoRemove', true)
		return obj
	end

	function obj.Period(delay, limit, warning)
		assert(isnumber(delay), 'The variable "delay" must be a number!')
		assert(isnumber(limit), 'The variable "limit" must be a number!')

		if warning ~= nil then
			assert(isfunction(warning), 'The variable "warning" must be a function!')
		end

		private.SetParam('limits', {
			delay = delay,
			limit = limit,
			warning = warning
		})

		return obj
	end

	-- Deprecated. The function does nothing.
	function obj.Register()
		return obj
	end

	return obj
end

-- Outdated method for backward compatibility
snet.RegisterCallback = function(name, func, autoremove, isadmin)
	local callback = snet.Callback(name, func)
	if autoremove then callback.AutoRemove() end
	if isadmin then callback.Protect() end
	return callback
end

snet.RemoveCallback = function(name)
	snet.storage.default[name] = nil
end

timer.Create('SNet_AutoResetRequestAfterTimeDealy', 1, 0, function()
	xpcall(function()
		for i = #snet.requests, 1, -1 do
			local data = snet.requests[i]
			if not data or not data.request or data.resetTime < RealTime() then
				table.remove(snet.requests, i)
			end
		end

		local count = #snet.requests
		if count >= 500 then
			print('SNET WARNING: Something is making too many requests (' .. count .. ')')
		end
	end, function(error_message)
		print('Attention! Something is creating errors in the request queue!')
		print('Contact the developer to identify issues.')
		print('SLIB NETWORK ERROR: ' .. error_message)
	end)
end)