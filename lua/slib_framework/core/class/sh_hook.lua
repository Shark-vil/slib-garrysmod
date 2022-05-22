local Class = {}

function Class.Get(hook_type, hook_name)
	local hooks_data = hook.GetTable()

	if hook_type and hooks_data[hook_type] then
		if hook_type and hook_name then
			return hooks_data[hook_type][hook_name]
		else
			return hooks_data[hook_type]
		end
	end

	return nil
end

function Class.Exists(hook_type, hook_name)
	return hook.Get(hook_type, hook_name) ~= nil
end

function Class.SafeRun(hook_type, ...)
	local result = nil
	local args = { ... }

	slib.def({
		try = function()
			result = { hook.Run(hook_type, unpack(args)) }
		end,
		catch = function(ex)
			slib.Error(ex)
		end
	})

	if result == nil then return end

	return unpack(result)
end

function Class.Add(...)
	return hook.Add(...)
end

function Class.Call(...)
	return hook.Call(...)
end

function Class.GetTable(...)
	return hook.GetTable(...)
end

function Class.Remove(...)
	return hook.Remove(...)
end

function Class.Run(...)
	return hook.Run(...)
end

slib.SetComponent('Hook', Class)