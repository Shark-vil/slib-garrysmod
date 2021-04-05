function slib.FileRead(path)
   local filePath = path .. '.dat'
   if not file.Exists(filePath, 'DATA') then return nil end

   local fileData = util.Decompress(file.Read(filePath, 'DATA'))
   local dataTable = util.JSONToTable(fileData)
   return dataTable[1]
end

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

function slib.FileDelete(path)
   local filePath = path .. '.dat'
   if not file.Exists(filePath, 'DATA') then return end
   file.Delete(filePath)
end