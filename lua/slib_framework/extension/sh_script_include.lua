local function exInclude(file_path, loading_text)
	if loading_text and isstring(loading_text) then
	   MsgN(string.Replace(loading_text, '{file}', file_path))
	end

	include(file_path)
end

local function getFileNetworkType(file_path)
	return string.lower(string.sub(string.GetFileFromFilename(file_path), 1, 2))
end

function slib.CreateIncluder(root_directory, loading_text)
	local obj = {}
	obj.root_directory = root_directory
	obj.loading_text = loading_text

	function obj:using(file_path)
		if self.root_directory then
			file_path = self.root_directory .. '/' .. file_path
		else
			file_path = file_path
		end

		local network_type = getFileNetworkType(file_path)

		if network_type == 'cl' or network_type == 'sh' then
			if SERVER then AddCSLuaFile(file_path) end
			if CLIENT and network_type == 'cl' then
				exInclude(file_path, self.loading_text)
			elseif network_type == 'sh' then
				exInclude(file_path, self.loading_text)
			end
		elseif network_type == 'sv' and SERVER then
			exInclude(file_path, self.loading_text)
		end
	end

	return obj
end

function slib.usingDirectory(root_scripts_directory_path, loading_text)
	local files, directories = file.Find(root_scripts_directory_path .. '/*', 'LUA')
	local files_list = {}

	table.SortDesc(files)

	for _, file_path in ipairs(files) do
		table.insert(files_list, {
			path = file_path,
			type = getFileNetworkType(file_path)
		})
	end

	local inc = slib.CreateIncluder(nil, loading_text)

	for i = #files_list, 1, -1 do
		local fileData = files_list[i]
		if fileData.type == 'sh' then
			inc:using(root_scripts_directory_path .. '/' .. fileData.path)
			table.remove(files_list, i)
		end
	end

	for i = #files_list, 1, -1 do
		local fileData = files_list[i]
		if fileData.type == 'sv' then
			inc:using(root_scripts_directory_path .. '/' .. fileData.path)
			table.remove(files_list, i)
		end
	end

	for i = #files_list, 1, -1 do
		local fileData = files_list[i]
		if fileData.type == 'cl' then
			inc:using(root_scripts_directory_path .. '/' .. fileData.path)
		end
	end

	for _, directory_path in ipairs(directories) do
		slib.usingDirectory(root_scripts_directory_path .. '/' .. directory_path, loading_text)
	end
end