local slib = slib
local snet = slib.Components.Network
--
snet.Callback('snet_file_delete_in_client', function(ply, path)
   slib.FileDelete(path)
end)

function snet.FileDeleteInServer(path)
   snet.InvokeServer('snet_file_delete_in_server', path)
end