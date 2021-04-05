snet.Callback('snet_file_delete_in_client', function(ply, path)
   slib.FileDelete(path)
end).Register()

function snet.FileDeleteInServer(path)
   snet.InvokeServer('snet_file_delete_in_server', path)
end