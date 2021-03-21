local processing_data = {}
local send_data = {}

if SERVER then
	util.AddNetworkString('slib_sv_bigdata_processing')	
   util.AddNetworkString('slib_cl_bigdata_processing')
   
   util.AddNetworkString('slib_sv_bigdata_receive')
   util.AddNetworkString('slib_sv_bigdata_receive_ok')
   util.AddNetworkString('slib_sv_bigdata_receive_error')

	util.AddNetworkString('slib_cl_bigdata_receive')
   util.AddNetworkString('slib_cl_bigdata_receive_ok')
   util.AddNetworkString('slib_cl_bigdata_receive_error')

   hook.Add('PlayerDisconnected', 'SlibBigDataPlayerDisconnected', function(ply)
      processing_data[ply] = nil

      for i = #send_data, 1, -1 do
         if send_data[i].ply == ply then
            table.remove(send_data, i)
         end
      end
   end)

   --[[
      Сервер принимает
   --]]
   net.Receive('slib_sv_bigdata_receive', function(len, ply)
      local name = net.ReadString()
      
      local error = false
      if snet.storage[name] == nil then
         error = true
      elseif snet.storage[name].adminOnly then
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
            snet.execute(name, ply, util.JSONToTable(result_data.data))
         elseif result_data.type == 'string' then
            snet.execute(name, ply, result_data.data)
         end
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

   net.Receive('slib_sv_bigdata_receive_error', function(len, ply)
      local name = net.ReadString()
      local index = net.ReadInt(10)

      local data = send_data[index]

      if data ~= nil and data.ply == ply then
         hook.Run('Slib_BigDataFailed', ply, name, data)
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
      
      local error = false
      if snet.storage[name] == nil then
         error = true
      elseif snet.storage[name].adminOnly then
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
            snet.execute(name, ply, util.JSONToTable(result_data.data))
         elseif result_data.type == 'string' then
            snet.execute(name, ply, result_data.data)
         end
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

   net.Receive('slib_cl_bigdata_receive_error', function(len)
      local name = net.ReadString()
      local index = net.ReadInt(10)

      local data = send_data[index]

      if data ~= nil then
         if data.progress_id ~= '' and data.progress_text ~= '' then
            notification.AddLegacy('An error occurred while sending data!', NOTIFY_ERROR, 5)
         end

         hook.Run('Slib_BigDataFailed', LocalPlayer(), name, data)
         send_data[index] = nil
      end
   end)
end

local function getNetParts(text, max_size)
   local parts = {}
   for i = 1, #text, max_size do
      parts[ #parts + 1 ] = text:sub(i, i + max_size - 1)

      coroutine.yield()
   end

   local net_parts = {}
   for _, string_part in ipairs(parts) do
      local compressed_data = util.Compress(string_part)
      local compressed_length = string.len(compressed_data)

      table.insert(net_parts, {
         data = compressed_data,
         length = compressed_length
      })

      coroutine.yield()
   end
   
   return coroutine.yield(net_parts)
end

local uid = 0
snet.InvokeBigData = function(name, ply, data, max_size, progress_id, progress_text)
   local request_data = ''

   if istable(data) then
      request_data = util.TableToJSON({
         type = 'table',
         data = util.TableToJSON(data)
      })
   elseif isstring(data) then
      request_data = util.TableToJSON({
         type = 'string',
         data = data
      })
   else
      return
   end

   if CLIENT then
      for _, v in ipairs(send_data) do
         if v.name == name then return end
      end
   else
      for _, v in ipairs(send_data) do
         if v.name == name and v.ply == ply then return end
      end
   end

   progress_id = progress_id or ''
   progress_text = progress_text or ''
   
   max_size = max_size or 5000
   uid = uid + 1

   local hook_name = 'SlibNetBigDataSender_' .. name .. uid
   local thread = coroutine.create(getNetParts)

   local index = table.insert(send_data, {
      name = name,
      ply = ply,
      net_parts = nil,
      max_parts = nil,
      current_part = 0,
      progress_id = progress_id,
      progress_text = progress_text,
   })
   
   if SERVER then
      hook.Run('Slib_PreparingBigdataSending', ply, name)
   else
      if progress_id ~= '' and progress_text ~= '' then
         notification.AddProgress('SlibBigDataPreparing_' .. name, "Data is being prepared for upload...")
      end
      hook.Run('Slib_PreparingBigdataSending', LocalPlayer(), name)
   end

   hook.Add('Think', hook_name, function()
      if coroutine.status(thread) == 'dead' then
         table.remove(send_data, index)
         hook.Remove('Think', hook_name)

         if SERVER then
            hook.Run('Slib_StopBigdataSending', ply, name)
         else
            if progress_id ~= '' and progress_text ~= '' then
               notification.Kill('SlibBigDataPreparing_' .. name)
               notification.AddLegacy('Failed to pack data to send!', NOTIFY_ERROR, 4)
            end

            hook.Run('Slib_StopBigdataSending', LocalPlayer(), name)
         end
         return
      end

      local worked, result = coroutine.resume(thread, request_data, max_size)
      if result == nil then return end
      hook.Remove('Think', hook_name)

      local net_parts = result
      local max_parts = #net_parts

      if net_parts == nil or #net_parts == 0 then return end

      send_data[index].net_parts = net_parts
      send_data[index].max_parts = max_parts
   
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

         if progress_id ~= '' and progress_text ~= '' then
            notification.Kill('SlibBigDataPreparing_' .. name)
         end
      end

      hook.Run('Slib_StartBigdataSending', ply, name)
   end)
end