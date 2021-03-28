snet.storage.bigdata = snet.storage.bigdata or {}

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
         data = util.TableToJSON(snet.GetNormalizeDataTable(data))
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
      for _, v in ipairs(snet.storage.bigdata) do
         if v.name == name then return end
      end
   else
      for _, v in ipairs(snet.storage.bigdata) do
         if v.name == name and v.ply == ply then return end
      end
   end

   progress_id = progress_id or ''
   progress_text = progress_text or ''
   max_size = max_size or 10000
   uid = uid + 1

   local hook_name = 'Slib_NetBigDataSender_' .. name .. uid
   local thread = coroutine.create(getNetParts)

   local index = table.insert(snet.storage.bigdata, {
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
         table.remove(snet.storage.bigdata, index)
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

      snet.storage.bigdata[index].net_parts = net_parts
      snet.storage.bigdata[index].max_parts = max_parts
   
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