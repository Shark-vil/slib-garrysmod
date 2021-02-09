slib.GlobalCvars = slib.GlobalCvars or {}

function slib:RegisterGlobalCvar(cvar_name, value, flag, helptext, min, max)
   if slib.GlobalCvars[cvar_name] == nil then
      helptext = helptext or ''

      CreateConVar(cvar_name, value, flag, helptext, min, max)

      slib.GlobalCvars[cvar_name] = {
         value = GetConVar(cvar_name):GetFloat(),
         flag = flag,
         helptext = helptext,
         min = min,
         max = max
      }

      if SERVER then
         cvars.AddChangeCallback(cvar_name, function(cvar_name, old_value, new_value)
            if old_value == new_value then return end
         
            timer.Remove('Slib_GCvars_OnChange_' .. cvar_name)
         
            timer.Create('Slib_GCvars_OnChange_' .. cvar_name, 0.5, 1, function()
               slib.GlobalCvars[cvar_name].value = new_value

               net.Start(slib.GetNetworkString('GCvars', 'ChangeFromClient'))
               net.WriteString(cvar_name)
               net.WriteFloat(new_value)
               net.Broadcast()
            end)
         end)
      end
   end
end