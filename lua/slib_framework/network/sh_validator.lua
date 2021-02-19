local netowrk_name_to_client = slib.GetNetworkString('Slib', 'EntityNetworkValidatorToClient')
local netowrk_name_to_server = slib.GetNetworkString('Slib', 'EntityNetworkValidatorToServer')

if SERVER then
   util.AddNetworkString(netowrk_name_to_client)
   util.AddNetworkString(netowrk_name_to_server)

   local callback_data = {}

   function snet.IsValidForClient(ply, func_callback, validator_name, validator_uid, timeout, ...)
      validator_name = validator_name or 'entity'
      timeout = timeout or 1

      local uid
      if validator_uid == nil then
         uid = ply:UserID() .. validator_name .. tostring(RealTime()) .. tostring(SysTime())
      else
         uid = ply:UserID() .. validator_name .. string.lower(validator_uid)
      end

      callback_data[uid] = function(ply, result)
         timer.Remove('SNet_IsValidForClient_' .. uid)
         func_callback(ply, result)
         callback_data[uid] = nil
      end

      timer.Create('SNet_IsValidForClient_' .. uid, timeout, 1, function()
         local data_callback = callback_data[uid]
         if data_callback ~= nil then
            data_callback(ply, false)
         end
      end)

      net.Start(netowrk_name_to_client)
      net.WriteString(uid)
      net.WriteString(validator_name)
      net.WriteType({ ... })
      net.Send(ply)
   end

   net.Receive(netowrk_name_to_server, function(len, ply)
      local uid = net.ReadString()
      local result = net.ReadBool()
      
      local data_callback = callback_data[uid]
      if data_callback ~= nil then
         data_callback(ply, result)
      end
   end)
else
   local validators = {}

   function snet.RegisterValidator(validator_name, callback)
      validators[validator_name] = callback
   end

   function snet.GetValidator(validator_name)
      return validators[validator_name]
   end

   snet.RegisterValidator('entity', function(ply, uid, ent)
      return IsValid(ent)
   end)

   net.Receive(netowrk_name_to_client, function()
      local ply = LocalPlayer()
      local uid = net.ReadString()
      local validator_name = net.ReadString()
      local args = net.ReadType()
      local success = false

      local validator_method = snet.GetValidator(validator_name)
      if validator_method == nil then return end
      
      success = validator_method(ply, uid, unpack(args))

      net.Start(netowrk_name_to_server)
      net.WriteString(uid)
      net.WriteBool(success)
      net.SendToServer()
   end)
end