function slib.FileWrite(path, data)
   local fileData

   if isstring(data) then
      fileData = { [1] = data }
   elseif istable(data) then
      fileData = { [1] = slib.GetNormalizeDataTable(data) }
   end

   if not fileData then return end

   file.Write(path .. '.dat', util.Compress(util.TableToJSON(fileData)))
end