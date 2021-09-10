local callback_storage = {}

function snet.GetCallbackList()
	return callback_storage
end

function snet.GetCallback(name)
	return callback_storage[name]
end

function snet.Callback(name, func)
	local private = {}
	private.name = name

	function private.SetParam(key, value)
		callback_storage[private.name] = callback_storage[private.name] or {}
		callback_storage[private.name][key] = value
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

	function obj.AutoDestroy()
		private.SetParam('auto_destroy', true)
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
function snet.RegisterCallback(name, func, auto_destroy, is_admin)
	local callback = snet.Callback(name, func)
	if auto_destroy then callback.AutoDestroy() end
	if is_admin then callback.Protect() end
	return callback
end

function snet.RemoveCallback(name)
	callback_storage[name] = nil
end