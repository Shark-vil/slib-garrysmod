local wait_read_data = {}

snet.Callback('snet_file_read_in_server_get', function(ply, customId, data)
   for i = #wait_read_data, 1, -1 do
      local value = wait_read_data[i]
      if value.id == customId then
         value.func(data)
         table.remove(wait_read_data, i)
         break
      end
   end
end).Register()

snet.Callback('snet_file_read_in_client', function(ply, path, customId)
   local data = slib.FileRead(path)
   snet.Invoke('snet_file_read_in_client_get', ply, customId, data)
end).Register()

function snet.FileReadInServer(path, onRead)
   local name = 'snet_file_read_in_server'
   local customId = slib.GenerateUid(name)

   local request = snet.Create(name, path, customId)
   request.id = customId

   table.insert(wait_read_data, {
      id = request.id,
      func = onRead
   })

   request.InvokeServer()
end