function slib.FileRead(path)
   local filePath = path .. '.dat'
   if not file.Exists(filePath, 'DATA') then return nil end

   local fileData = util.Decompress(file.Read(filePath, 'DATA'))
   local dataTable = util.JSONToTable(fileData)
   return dataTable[1]
end