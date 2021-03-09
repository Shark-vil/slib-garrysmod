local processing_data = {}
local send_data = {}

if SERVER then
	util.AddNetworkString('slib_sv_bigdata_processing')
   util.AddNetworkString('slib_sv_bigdata_processing_ok')
	
   util.AddNetworkString('slib_cl_bigdata_processing')
   util.AddNetworkString('slib_cl_bigdata_processing_ok')
   
   util.AddNetworkString('slib_sv_bigdata_receive')
   util.AddNetworkString('slib_sv_bigdata_receive_ok')

	util.AddNetworkString('slib_cl_bigdata_receive')
   util.AddNetworkString('slib_cl_bigdata_receive_ok')

   --[[
      Сервер принимает
   --]]
   net.Receive('slib_sv_bigdata_receive', function(len, ply)
      local name = net.ReadString()
      
      if snet.storage[name] == nil then return end
      if snet.storage[name].adminOnly then
         if not ply:IsAdmin() and not ply:IsSuperAdmin() then return end
      end

      local index = net.ReadInt(10)
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

   net.Receive('slib_sv_bigdata_processing', function(len, ply)
      if processing_data[ply] == nil then return end

      local name = net.ReadString()
      local index = net.ReadInt(10)

      if snet.storage[name] == nil then return end
      if processing_data[ply] == nil then return end
      if processing_data[ply][index] == nil then return end

      local current_part = net.ReadInt(10)
      local compressed_length = net.ReadUInt(24)
		local compressed_data = net.ReadData(compressed_length)

      local data = processing_data[ply][index]
      data.current_part = current_part
      table.insert(data.parts_data, compressed_data)

      if data.current_part >= data.max_parts then
         local data_string = ''

         for _, data in ipairs(data.parts_data) do
            data_string = data_string .. util.Decompress(data)
         end

         snet.execute(name, ply, util.JSONToTable(data_string))
         processing_data[ply][index] = nil
      else
         net.Start('slib_cl_bigdata_receive_ok')
         net.WriteString(name)
         net.WriteInt(index, 10)
         net.Send(ply)
      end
   end)

   --[[
      Сервер отправляет
   --]]
   net.Receive('slib_sv_bigdata_receive_ok', function(len, ply)
      local name = net.ReadString()
      local index = net.ReadInt(10)

      local data = send_data[index]

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
         hook.Run('Slib_BigDataFinished', ply, name, data)
         send_data[index] = nil
      end
   end)
else
   --[[
      Клиент принимает
   --]]
   net.Receive('slib_cl_bigdata_receive', function()
      local ply = LocalPlayer()
      local name = net.ReadString()
      
      if snet.storage[name] == nil then return end
      if snet.storage[name].adminOnly then
         if not ply:IsAdmin() and not ply:IsSuperAdmin() then return end
      end

      local index = net.ReadInt(10)
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

   net.Receive('slib_cl_bigdata_processing', function(len)
      local ply = LocalPlayer()
      local name = net.ReadString()
      local index = net.ReadInt(10)

      if snet.storage[name] == nil then return end
      if processing_data[index] == nil then return end

      local current_part = net.ReadInt(10)
      local compressed_length = net.ReadUInt(24)
		local compressed_data = net.ReadData(compressed_length)

      local data = processing_data[index]
      data.current_part = current_part
      table.insert(data.parts_data, compressed_data)

      if data.progress_id ~= '' and data.progress_text ~= '' then
         notification.AddProgress(data.progress_id, data.progress_text, (1 / data.max_parts) 
            * data.current_part)
      end

      if data.current_part >= data.max_parts then
         local data_string = ''

         for _, data in ipairs(data.parts_data) do
            data_string = data_string .. util.Decompress(data)
         end

         snet.execute(name, ply, util.JSONToTable(data_string))
         
         if data.progress_id ~= '' and data.progress_text ~= '' then
            notification.Kill(data.progress_id)
            notification.AddLegacy('Success! ' .. data.progress_text, NOTIFY_GENERIC, 3)
         end

         processing_data[index] = nil
      else
         net.Start('slib_sv_bigdata_receive_ok')
         net.WriteString(name)
         net.WriteInt(index, 10)
         net.SendToServer()
      end
   end)

   --[[
      Клиент отправляет
   --]]
   net.Receive('slib_cl_bigdata_receive_ok', function()
      local name = net.ReadString()
      local index = net.ReadInt(10)

      local data = send_data[index]

      if data == nil then return end

      data.current_part = data.current_part + 1
      local part = data.net_parts[data.current_part]

      net.Start('slib_sv_bigdata_processing')
      net.WriteString(name)
      net.WriteInt(index, 10)
      net.WriteInt(data.current_part, 10)
      net.WriteUInt(part.length, 24)
      net.WriteData(part.data, part.length)
      net.SendToServer()

      if data.progress_id ~= '' and data.progress_text ~= '' then
         notification.AddProgress(data.progress_id, data.progress_text, (1 / data.max_parts) 
            * data.current_part)
      end

      if data.current_part >= data.max_parts then
         if data.progress_id ~= '' and data.progress_text ~= '' then
            notification.Kill(data.progress_id)
            notification.AddLegacy('Success! ' .. data.progress_text, NOTIFY_GENERIC, 3)
         end

         hook.Run('Slib_BigDataFinished', LocalPlayer(), name, data)
         send_data[index] = nil
      end
   end)
end

local function splitByChunk(text, chunkSize)
   local s = {}
   for i = 1, #text, chunkSize do
      s[ #s + 1 ] = text:sub(i, i + chunkSize - 1)
   end
   return s
end

snet.InvokeBigData = function(name, ply, string_data, max_size, progress_id, progress_text)
   if not istable(string_data) then return end

   progress_id = progress_id or ''
   progress_text = progress_text or ''
   
   max_size = max_size or 4000

   local parts = splitByChunk(util.TableToJSON(string_data), max_size)
   local net_parts = {}

   for _, string_part in ipairs(parts) do
      local compressed_data = util.Compress(string_part)
      local compressed_length = string.len(compressed_data)

      table.insert(net_parts, {
         data = compressed_data,
         length = compressed_length
      })
   end

   local max_parts = #net_parts
   local index = table.insert(send_data, {
      name = name,
      net_parts = net_parts,
      max_parts = max_parts,
      current_part = 0,
      progress_id = progress_id,
      progress_text = progress_text,
   })

   if SERVER then
      net.Start('slib_cl_bigdata_receive')
      net.WriteString(name)
      net.WriteInt(index, 10)
      net.WriteInt(max_parts, 10)
      net.WriteString(progress_id)
      net.WriteString(progress_text)
      net.Send(ply)
   else
      net.Start('slib_sv_bigdata_receive')
      net.WriteString(name)
      net.WriteInt(index, 10)
      net.WriteInt(max_parts, 10)
      net.SendToServer()
   end
end