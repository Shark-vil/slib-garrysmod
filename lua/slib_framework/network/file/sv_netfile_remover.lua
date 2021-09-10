local slib = slib
local snet = snet
--
snet.Callback('snet_file_delete_in_server', function(ply, path)
   slib.FileDelete(path)
end).Protect()

function snet.FileDeleteInClient(ply, path)
   snet.Invoke('snet_file_delete_in_client', ply, path)
end