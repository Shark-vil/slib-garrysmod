local access = slib.Components.Access
local gcvars = slib.Components.GlobalCvar
local GetConVar = GetConVar
local tostring = tostring
--

snet.Callback('slib_gcvars_change_from_server', function(ply, cvar_name, value)
	local cvar_data = slib.Storage.GlobalCvar[cvar_name]
	if not cvar_data then return end

	slib.DebugLog('Client ', ply, ' try update cvar - ', cvar_name, ' (', value, ')')

	if cvar_data.send_server and access.IsValid(ply, cvar_data.access) then
		slib.DebugLog('Client ', ply, ' update cvar - ', cvar_name, ' (', value, ')')

		if GetConVar(cvar_name):GetString() == tostring(value) then
			return
		end

		cvar_data.send_server = false

		RunConsoleCommand(cvar_name, value)
		gcvars.Update(cvar_name, value)

		timer.Simple(.5, function()
			if cvar_data.send_server then return end
			cvar_data.send_server = true
		end)

		snet.Invoke('slib_gcvars_server_update_success', ply, cvar_name, value)
	else
		snet.Invoke('slib_gcvars_server_update_error', ply, cvar_name, cvar_data.value)
	end
end)

hook.Add('slib.FirstPlayerSpawn', 'slib.UpdateGlobalCvarsFromClient', function(ply)
	gcvars.Update()

	local sync_data = {}

	for cvar_name, cvar_data in pairs(slib.Storage.GlobalCvar) do
		table.insert(sync_data, {
			cvar_name = cvar_name,
			cvar_value = cvar_data.value
		})
	end

	snet.Invoke('slib_gcvars_client_player_sync', ply, sync_data)
end)