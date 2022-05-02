hook.Add('PreGamemodeLoaded', 'SlibInitializeHookExtension', function()
	function hook.Get(hook_type, hook_name)
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

	function hook.Exists(hook_type, hook_name)
		return hook.Get(hook_type, hook_name) ~= nil
	end
end)