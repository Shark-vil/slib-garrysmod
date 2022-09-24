local gcvars = slib.Components.GlobalCvar
local AccessComponent = slib.Components.Access
local isnumber = isnumber
local isbool = isbool
local isstring = isstring
local GetConVar = GetConVar
local pairs = pairs
local table_remove = table.remove
--

function gcvars.Update(cvar_name, value)
	if cvar_name and slib.Storage.GlobalCvar[cvar_name] then
		local data = slib.Storage.GlobalCvar[cvar_name]
		data.value = value ~= nil and tostring(value) or GetConVar(cvar_name):GetString()
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

		do
			local new_flag = flag

			if (isnumber(flag) and flag == FCVAR_REPLICATED) or not table.isArray(flag) then
				new_flag = FCVAR_NONE
			else
				for i = #new_flag, 1, -1 do
					local flag_value = new_flag[i]
					if not isnumber(flag_value) or flag_value == FCVAR_REPLICATED then
						table_remove(new_flag, i)
					end
				end

				if #new_flag == 0 then
					new_flag = FCVAR_NONE
				end
			end

			flag = new_flag
		end

		helptext = helptext or ''
		CreateConVar(cvar_name, value, flag, helptext, min, max)

		slib.Storage.GlobalCvar[cvar_name] = {
			value = GetConVar(cvar_name):GetString(),
			flag = flag,
			helptext = helptext,
			min = min,
			max = max,
			access = access_data and AccessComponent:Make(access_data) or access_data,
		}

		slib.DebugLog('Register global cvar - ', cvar_name)

		cvars.AddChangeCallback(cvar_name, function(_, old_value, new_value)
			if old_value == new_value then return end

			local cvar_data = slib.Storage.GlobalCvar[cvar_name]
			if not cvar_data then return end

			timer.Remove('slib.SystemTimer.Cvars.OnChange.' .. cvar_name)

			timer.Create('slib.SystemTimer.Cvars.OnChange.' .. cvar_name, 0.5, 1, function()
				if SERVER then
					slib.DebugLog('Change cvaer on serverside. Update cvar - ', cvar_name, ' (', value, ')')

					gcvars.Update(cvar_name, new_value)
					snet.InvokeAll('slib_gcvars_server_update_success', cvar_name, new_value)
				end

				hook.Run('slib.OnChangeGlobalCvar', cvar_name, old_value, new_value)
			end)
		end, 'slib_GlobalCvars_OnChange_' .. cvar_name)
	end

	return public
end