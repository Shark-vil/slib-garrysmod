local access = slib.Components.Access
local gcvars = slib.Components.GlobalCvar
local GetConVar = GetConVar
local tostring = tostring
--

snet.Callback('slib_gcvars_change_from_server', function(ply, cvar_name, value)
	local cvar_data = slib.Storage.GlobalCvar[cvar_name]

	slib.DebugLog('Client ', ply, ' try update cvar - ', cvar_name, ' (', value, ')')

	if cvar_data ~= nil and cvar_data.send_server and access.IsValid(ply, cvar_data.access) then
		slib.DebugLog('Client ', ply, ' update cvar - ', cvar_name, ' (', value, ')')

		if GetConVar(cvar_name):GetString() == tostring(value) then
			return
		end

		cvar_data.send_server = false

		RunConsoleCommand(cvar_name, value)
		gcvars.Update(cvar_name)

		timer.Simple(.5, function()
			if cvar_data.send_server then return end
			cvar_data.send_server = true
		end)

		snet.Invoke('slib_gcvars_server_update_success', ply, cvar_name, value)
	else
		snet.Invoke('slib_gcvars_server_update_error', ply, cvar_name, cvar_data.value)
	end
end)