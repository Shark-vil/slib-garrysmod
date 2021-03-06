local cvar_locker = {}
local cvar_locker_another = {}

snet.RegisterCallback('slib_gcvars_register', function(_, cvars_table)
   slib.GlobalCvars = cvars_table

   for cvar_name, cvar_data in pairs(slib.GlobalCvars) do
      if not tobool(GetConVar(cvar_name)) then   
         ErrorNoHalt('The global variable must be created on both the server and client!')
         goto skip
      else
         RunConsoleCommand(cvar_name, cvar_data.value)
         MsgN('Successful cvar sync for client! CVAR ['.. cvar_name ..'] - ' .. cvar_data.value)
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

         slib.GlobalCvarsUpdate(convar_name)
         
         if cvar_locker[convar_name] or cvar_locker_another[convar_name] then return end
         snet.InvokeServer('slib_gcvars_change_from_server', convar_name, value_new)
      end)

      ::skip::
   end
end)

snet.RegisterCallback('slib_gcvars_change_from_client', function(_, cvar_name, value)
   cvar_locker_another[cvar_name] = true
   RunConsoleCommand(cvar_name, value)

   timer.Create('slib_gcvars_reset_cvar_another_locker_' .. cvar_name, 0.2, 1, function()
      if not cvar_locker_another[cvar_name] then return end
      cvar_locker_another[cvar_name] = false
   end)
end)