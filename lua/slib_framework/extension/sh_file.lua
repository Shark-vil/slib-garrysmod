local isstring = isstring
local istable = istable
local slib_GetNormalizeDataTable = slib.GetNormalizeDataTable
local string_GetPathFromFilename = string.GetPathFromFilename
local file_CreateDir = file.CreateDir
local file_Write = file.Write
local file_Find = file.Find
local file_Delete = file.Delete
local file_Exists = file.Exists
local file_Read = file.Read
local util_Compress = util.Compress
local util_Decompress = util.Decompress
local util_JSONToTable = util.JSONToTable
local util_TableToJSON = util.TableToJSON
--

function slib.FileExists(path)
	return file_Exists(path .. '.dat', 'DATA')
end

function slib.FileRead(path)
	local filePath = path .. '.dat'
	if not file_Exists(filePath, 'DATA') then return nil end

	local fileData = util_Decompress(file_Read(filePath, 'DATA'))
	local dataTable = util_JSONToTable(fileData)
	return dataTable[1]
end

function slib.FileWrite(path, data)
	local filePath = path .. '.dat'
	local directoryPath = string_GetPathFromFilename(filePath)
	local fileData

	if isstring(data) then
		fileData = { [1] = data }
	elseif istable(data) then
		fileData = { [1] = slib_GetNormalizeDataTable(data) }
	end

	if not fileData then return end

	file_CreateDir(directoryPath)
	file_Write(filePath, util_Compress(util_TableToJSON(fileData)))
end

function slib.FileDelete(path)
	local filePath = path .. '.dat'
	if not file_Exists(filePath, 'DATA') then return end
	file_Delete(filePath)
end

function slib.FileExists(file_path, data_type)
	file_path = file_path:gsub('\\', '/')
	if file_Exists(file_path, data_type) then return true end

	if file_path:sub(#file_path) ~= '/' then
		file_path = file_path .. '/'
	end

	local file_name = string.GetFileFromFilename(file_path)
	local directory_path = string.GetPathFromFilename(file_path)
	local files, _ = file_Find(directory_path .. '*', data_type)

	if files then
		for _, other_file_name in ipairs(files) do
			if other_file_name == file_name then
				return true
			end
		end
	end

	return false
end