local gcvars = slib.Components.GlobalCvar
local AccessComponent = slib.Components.Access

function gcvars.Update(cvar_name)
	if cvar_name then
		local data = slib.Storage.GlobalCvar[cvar_name]

		if data then
			data.value = GetConVar(cvar_name):GetString()
		end
	else
		for cvar_name_key, _ in pairs(slib.Storage.GlobalCvar) do
			gcvars.Update(cvar_name_key)
		end
	end
end

function gcvars.Register(cvar_name, value, flag, helptext, min, max, access_data)
	local public = {}

	function public.Access(cvar_access_data)
		if not slib.Storage.GlobalCvar[cvar_name] or not cvar_access_data then return end
		slib.Storage.GlobalCvar[cvar_name].access = AccessComponent:Make(cvar_access_data)
	end

	if slib.Storage.GlobalCvar[cvar_name] == nil then
		if not isnumber(value) and not isbool(value) and not isstring(value) then return end
		helptext = helptext or ''
		CreateConVar(cvar_name, value, flag, helptext, min, max)

		slib.Storage.GlobalCvar[cvar_name] = {
			value = GetConVar(cvar_name):GetString(),
			flag = flag,
			helptext = helptext,
			min = min,
			max = max,
			access = access_data and AccessComponent:Make(access_data) or access_data
		}

		if SERVER then
			cvars.AddChangeCallback(cvar_name, function(_, old_value, new_value)
				if old_value == new_value then return end
				timer.Remove('Slib_GCvars_OnChange_' .. cvar_name)

				timer.Create('Slib_GCvars_OnChange_' .. cvar_name, 0.5, 1, function()
					gcvars.Update(cvar_name)
					snet.InvokeAll('slib_gcvars_change_from_client', cvar_name, new_value)
				end)
			end)
		end
	end

	return public
end