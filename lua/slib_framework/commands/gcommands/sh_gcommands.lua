local client_commands = {}
local server_commands = {}

if CLIENT then
   snet.RegisterCallback('slib_global_commands_client_rpc', function(_, ply, cmd, args)
      local func = client_commands[cmd]
      if not func or not isfunction(func) then return end
      func(ply, cmd, args)
   end)
else
   snet.Callback('slib_global_commands_server_rpc', function(net_player, ply, cmd, args)
      local func = server_commands[cmd]
      if not func or not isfunction(func) then return end
      func(ply, cmd, args)
      snet.InvokeIgnore('slib_global_commands_client_rpc', net_player, ply, cmd, args)
   end).Protect().Register()
end

function slib:RegisterGlobalCommand(name, client_callback, server_callback, autoComplete, helpText, flags)
   local autoComplete = autoComplete or nil
   local helpText = helpText or nil
   local flags = flags or 0

   if CLIENT then
      client_commands[name] = client_callback
   else
      server_commands[name] = server_callback
   end

   concommand.Add(name, function(ply, cmd, args)
      local isReplicate

      if SERVER then
         if server_callback and isfunction(server_callback) then
            isReplicate = server_callback(ply, cmd, args)
         end

         if isReplicate == nil or (isbool(isReplicate) and isReplicate == true) then
            snet.InvokeAll('slib_global_commands_client_rpc', ply, cmd, args)
         end
      else
         if client_callback and isfunction(client_callback) then
            isReplicate = client_callback(ply, cmd, args)
         end

         if isReplicate == nil or (isbool(isReplicate) and isReplicate == true) then
            snet.InvokeServer('slib_global_commands_server_rpc', ply, cmd, args)
         end
      end
   end, autoComplete, helpText, flags)
end