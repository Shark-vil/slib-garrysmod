local slib = slib
local snet = slib.Components.Network
local access = slib.Components.Access
local gcvars = slib.Components.GlobalCvar
local RunConsoleCommand = RunConsoleCommand
--

snet.Callback('slib_gcvars_change_from_server', function(ply, cvar_name, value)
	local cvar_data = slib.Storage.GlobalCvar[cvar_name]

	if cvar_data ~= nil and access.IsValid(ply, cvar_data.access) then
		RunConsoleCommand(cvar_name, value)
		gcvars.Update(cvar_name)
	end
end)

hook.Add('SlibPlayerFirstSpawn', 'Slib_GCvars_RegisterForPlayer', function(ply)
	gcvars.Update()
	snet.Invoke('slib_gcvars_register', ply, slib.Storage.GlobalCvar)
end)