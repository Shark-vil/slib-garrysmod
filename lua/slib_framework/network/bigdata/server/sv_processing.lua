local processing_data = {}

hook.Add('PlayerDisconnected', 'SlibBigDataPlayerDisconnected', function(ply)
   processing_data[ply] = nil

   for i = #snet.storage.bigdata, 1, -1 do
      if snet.storage.bigdata[i].ply == ply then
         table.remove(snet.storage.bigdata, i)
      end
   end
end)

-- Executed for the first time before data processing
-- CLIENT (sh_callback_bigdata.lua) --> SERVER
net.Receive('slib_sv_bigdata_receive', function(len, ply)
   local name = net.ReadString()
   
   local error = false
   if snet.storage.default[name] == nil then
      error = true
   elseif snet.storage.default[name].adminOnly then
      if not ply:IsAdmin() and not ply:IsSuperAdmin() then
         error = true
      end
   end

   local index = net.ReadInt(10)

   if error then
      net.Start('slib_cl_bigdata_receive_error')
      net.WriteString(name)
      net.WriteInt(index, 10)
      net.Send(ply)
      return
   end

   local max_parts = net.ReadInt(10)

   processing_data[ply] = processing_data[ply] or {}
   processing_data[ply][index] = {
      max_parts = max_parts,
      current_part = 0,
      parts_data = {}
   }

   net.Start('slib_cl_bigdata_receive_ok')
   net.WriteString(name)
   net.WriteInt(index, 10)
   net.Send(ply)
end)

-- Called every time a new batch of data is received from the client
-- CLIENT (slib_cl_bigdata_receive_ok) --> SERVER
net.Receive('slib_sv_bigdata_processing', function(len, ply)
   if processing_data[ply] == nil then return end

   local name = net.ReadString()
   local index = net.ReadInt(10)

   if snet.storage.default[name] == nil then return end
   if processing_data[ply] == nil then return end
   if processing_data[ply][index] == nil then return end

   local current_part = net.ReadInt(10)
   local compressed_length = net.ReadUInt(24)
   local compressed_data = net.ReadData(compressed_length)

   local data = processing_data[ply][index]
   data.current_part = current_part
   table.insert(data.parts_data, compressed_data)

   if data.current_part == 1 then
      hook.Run('Slib_StartBigdataSending', ply, name)
   end

   if data.current_part >= data.max_parts then
      local data_string = ''

      for _, data in ipairs(data.parts_data) do
         data_string = data_string .. util.Decompress(data)
      end

      processing_data[ply][index] = nil

      local result_data = util.JSONToTable(data_string)
      if result_data.type == 'table' then
         snet.execute('none', name, ply, false, util.JSONToTable(result_data.data))
      elseif result_data.type == 'string' then
         snet.execute('none', name, ply, false, result_data.data)
      end
   else
      net.Start('slib_cl_bigdata_receive_ok')
      net.WriteString(name)
      net.WriteInt(index, 10)
      net.Send(ply)
   end
end)