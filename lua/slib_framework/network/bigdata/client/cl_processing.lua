local processing_data = {}

-- Executed for the first time before data processing
-- SERVER (sh_callback_bigdata.lua) --> CLIENT
net.Receive('slib_cl_bigdata_receive', function()
   local ply = LocalPlayer()
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
      net.Start('slib_sv_bigdata_receive_error')
      net.WriteString(name)
      net.WriteInt(index, 10)
      net.SendToServer()
      return
   end

   local max_parts = net.ReadInt(10)
   local progress_id = net.ReadString()
   local progress_text = net.ReadString()

   processing_data[index] = {
      max_parts = max_parts,
      current_part = 0,
      parts_data = {},
      progress_id = progress_id,
      progress_text = progress_text,
   }

   net.Start('slib_sv_bigdata_receive_ok')
   net.WriteString(name)
   net.WriteInt(index, 10)
   net.SendToServer()
end)

-- Called every time a new batch of data is received from the server
-- SERVER (slib_sv_bigdata_receive_ok) --> CLIENT
net.Receive('slib_cl_bigdata_processing', function(len)
   local ply = LocalPlayer()
   local name = net.ReadString()
   local index = net.ReadInt(10)

   if snet.storage.default[name] == nil then return end
   if processing_data[index] == nil then return end

   local current_part = net.ReadInt(10)
   local compressed_length = net.ReadUInt(24)
   local compressed_data = net.ReadData(compressed_length)

   local data = processing_data[index]
   data.current_part = current_part
   table.insert(data.parts_data, compressed_data)

   if data.current_part == 1 then
      hook.Run('Slib_StartBigdataSending', ply, name)
   end

   if data.progress_id ~= '' and data.progress_text ~= '' then
      notification.AddProgress(data.progress_id, data.progress_text, (1 / data.max_parts) 
         * data.current_part)
   end

   if data.current_part >= data.max_parts then
      local data_string = ''

      for _, data in ipairs(data.parts_data) do
         data_string = data_string .. util.Decompress(data)
      end
      
      if data.progress_id ~= '' and data.progress_text ~= '' then
         notification.Kill(data.progress_id)
         notification.AddLegacy('Success! ' .. data.progress_text, NOTIFY_GENERIC, 3)
      end

      processing_data[index] = nil

      local result_data = util.JSONToTable(data_string)
      if result_data.type == 'table' then
         snet.execute('none', name, ply, false, util.JSONToTable(result_data.data))
      elseif result_data.type == 'string' then
         snet.execute('none', name, ply, false, result_data.data)
      end
   else
      net.Start('slib_sv_bigdata_receive_ok')
      net.WriteString(name)
      net.WriteInt(index, 10)
      net.SendToServer()
   end
end)