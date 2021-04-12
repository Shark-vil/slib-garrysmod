slib.GlobalCvars = slib.GlobalCvars or {}

slib.GlobalCvarsUpdate = function(cvar_name)
   if cvar_name then
      local data = slib.GlobalCvars[cvar_name]
      if data then
         data.value = GetConVar(cvar_name):GetString()
      end
   else
      for cvar_name, _ in pairs(slib.GlobalCvars) do
         slib.GlobalCvarsUpdate(cvar_name)
      end
   end
end

function slib:RegisterGlobalCvar(cvar_name, value, flag, helptext, min, max)
   if slib.GlobalCvars[cvar_name] == nil then
      if not isnumber(value) and not isbool(value) and not isstring(value) then return end
      helptext = helptext or ''

      CreateConVar(cvar_name, value, flag, helptext, min, max)

      slib.GlobalCvars[cvar_name] = {
         value = GetConVar(cvar_name):GetString(),
         flag = flag,
         helptext = helptext,
         min = min,
         max = max,
      }

      if SERVER then
         cvars.AddChangeCallback(cvar_name, function(cvar_name, old_value, new_value)
            if old_value == new_value then return end
            timer.Remove('Slib_GCvars_OnChange_' .. cvar_name)
            timer.Create('Slib_GCvars_OnChange_' .. cvar_name, 0.5, 1, function()
               slib.GlobalCvarsUpdate(cvar_name)
               snet.InvokeAll('slib_gcvars_change_from_client', cvar_name, new_value)
            end)
         end)
      end
   end
end