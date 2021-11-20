local function Initialize()
	hook = hook or {}

	function hook.Exists(hook_type, hook_name)
		return hook.Get(hook_type, hook_name) ~= nil
	end

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

	hook.Remove('PreGamemodeLoaded', 'SlibInitializeHookExtension')
end
hook.Add('PreGamemodeLoaded', 'SlibInitializeHookExtension', Initialize)