-- Called when the client requests a new batch of data
-- CLIENT (slib_cl_bigdata_receive / slib_cl_bigdata_processing) --> SERVER
net.Receive('slib_sv_bigdata_receive_ok', function(len, ply)
   local name = net.ReadString()
   local index = net.ReadInt(10)

   local data = snet.storage.bigdata[index]

   if data == nil then return end

   data.current_part = data.current_part + 1
   local part = data.net_parts[data.current_part]

   net.Start('slib_cl_bigdata_processing')
   net.WriteString(name)
   net.WriteInt(index, 10)
   net.WriteInt(data.current_part, 10)
   net.WriteUInt(part.length, 24)
   net.WriteData(part.data, part.length)
   net.Send(ply)

   if data.current_part >= data.max_parts then
      hook.Run('SnetBigDataFinished', ply, name, data)
      snet.storage.bigdata[index] = nil
   end
end)

-- Executed once if the client rejects the request.
-- CLIENT (slib_cl_bigdata_receive) --> SERVER
net.Receive('slib_sv_bigdata_receive_error', function(len, ply)
   local name = net.ReadString()
   local index = net.ReadInt(10)

   local data = snet.storage.bigdata[index]

   if data ~= nil and data.ply == ply then
      hook.Run('SnetBigDataFailed', ply, name, data)
      snet.storage.bigdata[index] = nil
   end
end)