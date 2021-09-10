local slib = slib
local file = file
local util = util
local isstring = isstring
local istable = istable
--

function slib.FileExists(path)
	return file.Exists(path .. '.dat', 'DATA')
end

function slib.FileRead(path)
	local filePath = path .. '.dat'
	if not file.Exists(filePath, 'DATA') then return nil end

	local fileData = util.Decompress(file.Read(filePath, 'DATA'))
	local dataTable = util.JSONToTable(fileData)
	return dataTable[1]
end

function slib.FileWrite(path, data)
	local filePath = path .. '.dat'
	local directoryPath = string.GetPathFromFilename(filePath)
	local fileData

	if isstring(data) then
		fileData = { [1] = data }
	elseif istable(data) then
		fileData = { [1] = slib.GetNormalizeDataTable(data) }
	end

	if not fileData then return end

	file.CreateDir(directoryPath)
	file.Write(filePath, util.Compress(util.TableToJSON(fileData)))
end

function slib.FileDelete(path)
	local filePath = path .. '.dat'
	if not file.Exists(filePath, 'DATA') then return end
	file.Delete(filePath)
end