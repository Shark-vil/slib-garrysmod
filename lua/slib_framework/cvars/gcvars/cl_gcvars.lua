local n_gcvar_register_cvars = slib.GetNetworkString('GCvars', 'RegisterCvars')
local n_gcvar_change_from_serer = slib.GetNetworkString('GCvars', 'ChangeFromServer')
local n_gcvar_change_from_client = slib.GetNetworkString('GCvars', 'ChangeFromClient')

local cvar_locker = {}
local cvar_locker_another = {}

net.Receive(n_gcvar_register_cvars, function()
   slib.GlobalCvars = net.ReadTable()

   for cvar_name, cvar_data in pairs(slib.GlobalCvars) do
      if not tobool(GetConVar(cvar_name)) then
         CreateConVar(cvar_name, cvar_data.value, cvar_data.flag, cvar_data.helptext, cvar_data.min, cvar_data.max)
      else
         RunConsoleCommand(cvar_name, cvar_data.value)
      end

      cvar_locker[cvar_name] = cvar_locker[cvar_name] or false

      cvars.AddChangeCallback(cvar_name, function(convar_name, value_old, value_new)
         if value_old == value_new then return end
         
         if not cvar_locker_another[convar_name] then
            if not LocalPlayer():IsAdmin() and not LocalPlayer():IsSuperAdmin() then
               if not cvar_locker[convar_name] then
                  cvar_locker[convar_name] = true
                  timer.Remove('slib_gcvars_back_cvar_' .. convar_name)

                  timer.Create('slib_gcvars_back_cvar_' .. convar_name, 0.1, 1, function()
                     if not cvar_locker[convar_name] then return end
                     RunConsoleCommand(convar_name, value_old)

                     timer.Remove('slib_gcvars_reset_back_cvar_' .. convar_name)
                     timer.Create('slib_gcvars_reset_back_cvar_' .. convar_name, 0.1, 1, function()
                        if not cvar_locker[convar_name] then return end
                        cvar_locker[convar_name] = false
                     end)
                  end)
               end
               return
            end
         end

         slib.GlobalCvars[convar_name].value = value_new
         
         if cvar_locker[convar_name] or cvar_locker_another[convar_name] then return end

         net.Start(n_gcvar_change_from_serer)
         net.WriteString(convar_name)
         net.WriteFloat(value_new)
         net.SendToServer()
      end)
   end
end)

net.Receive(n_gcvar_change_from_client, function()
   local cvar_name = net.ReadString()
   local value = net.ReadFloat()

   cvar_locker_another[cvar_name] = true
   RunConsoleCommand(cvar_name, value)

   timer.Create('slib_gcvars_reset_cvar_another_locker_' .. cvar_name, 0.2, 1, function()
      if not cvar_locker_another[cvar_name] then return end
      cvar_locker_another[cvar_name] = false
   end)
end)