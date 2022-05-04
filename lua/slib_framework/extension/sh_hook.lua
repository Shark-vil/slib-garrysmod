local function Get(hook_type, hook_name)
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
hook.Get = Get

local function Exists(hook_type, hook_name)
	return hook.Get(hook_type, hook_name) ~= nil
end
hook.Exists = Exists

hook.Add('PreGamemodeLoaded', 'SlibInitializeHookExtension', function()
	if hook.Get ~= Get then hook.Get = Get end
	if hook.Exists ~= Exists then hook.Exists = Exists end
end)