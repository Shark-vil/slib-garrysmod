snet.Callback('snet_file_write_to_server', function(ply, path, data)
   slib.FileWrite(path, data)
end).Protect().Register()

function snet.FileWriteToClient(ply, path, data)
   snet.Invoke('snet_file_write_to_client', ply, path, data)
end