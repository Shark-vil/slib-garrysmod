local slib = slib
local snet = slib.Components.Network
--
snet.Callback('snet_file_write_to_client', function(ply, path, data)
   slib.FileWrite(path, data)
end)

function snet.FileWriteToServer(path, data)
   snet.InvokeServer('snet_file_write_to_server', path, data)
end