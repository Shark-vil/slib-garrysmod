snet.Callback('slib_gcvars_change_from_server', function(ply, cvar_name, value)
   if slib.GlobalCvars[cvar_name] ~= nil then
      RunConsoleCommand(cvar_name, value)
      slib.GlobalCvarsUpdate(cvar_name)
   end
end).Protect().Register()

hook.Add("SlibPlayerFirstSpawn", "Slib_GCvars_RegisterForPlayer", function(ply)
   slib.GlobalCvarsUpdate()
   snet.Invoke('slib_gcvars_register', ply, slib.GlobalCvars)
end)