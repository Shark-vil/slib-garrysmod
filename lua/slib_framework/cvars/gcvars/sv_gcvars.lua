local n_gcvar_register_cvars = slib.GetNetworkString('GCvars', 'RegisterCvars')
local n_gcvar_change_from_serer = slib.GetNetworkString('GCvars', 'ChangeFromServer')
local n_gcvar_change_from_client = slib.GetNetworkString('GCvars', 'ChangeFromClient')

util.AddNetworkString(n_gcvar_register_cvars)
util.AddNetworkString(n_gcvar_change_from_serer)
util.AddNetworkString(n_gcvar_change_from_client)

net.Receive(n_gcvar_change_from_serer, function(len, ply)
   if not ply:IsAdmin() and not ply:IsSuperAdmin() then return end

   local cvar_name = net.ReadString()
   local value = net.ReadFloat()
   local cvar = GetConVar(cvar_name)

   if slib.GlobalCvars[cvar_name] ~= nil and tobool(cvar) and cvar:GetFloat() ~= value then
      RunConsoleCommand(cvar_name, value)
   end
end)

hook.Add("PlayerSpawn", "Slib_GCvars_RegisterForPlayer", function(ply)
   if ply:slibGetVar('GCvarsIsLoad') then return end

   timer.Simple(3, function()
      if not IsValid(ply) then return end

      net.Start(n_gcvar_register_cvars)
      net.WriteTable(slib.GlobalCvars)
      net.Send(ply)
   end)
end)