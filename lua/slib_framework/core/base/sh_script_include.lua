local valid_prefix_list = { 'cl', 'sv', 'sh' }

local function ScriptInclude(file_path, loading_text)
	if not isstring(file_path) or not file.Exists(file_path, 'LUA') then
		MsgN('[SLibrary] Script failed load - ' .. file_path)
		return
	end

	if loading_text and isstring(loading_text) then
	   MsgN(string.Replace(loading_text, '{file}', file_path))
	end

	return include(file_path)
end

local function GetFileNetworkType(file_path)
	return string.lower(string.sub(string.GetFileFromFilename(file_path), 1, 2))
end

function slib.CreateIncluder(root_directory, loading_text)
	local obj = {}
	obj.root_directory = root_directory
	obj.loading_text = loading_text

	function obj:using(file_path, disable_auto_include)
		disable_auto_include = disable_auto_include or false

		if self.root_directory then
			file_path = self.root_directory .. '/' .. file_path
		else
			file_path = file_path
		end

		local network_type = GetFileNetworkType(file_path)
		if not network_type or not table.HasValue(valid_prefix_list, network_type) then
			ErrorNoHalt('[SLIB.ERROR] The prefix was not found in the file name. The script '
				.. file_path .. ' will not be included!')
		end

		if network_type == 'cl' or network_type == 'sh' then
			if SERVER then AddCSLuaFile(file_path) end

			if not disable_auto_include then
				if CLIENT and network_type == 'cl' then
					return ScriptInclude(file_path, self.loading_text)
				elseif network_type == 'sh' then
					return ScriptInclude(file_path, self.loading_text)
				end
			end
		elseif network_type == 'sv' and SERVER and not disable_auto_include then
			return ScriptInclude(file_path, self.loading_text)
		end
	end

	return obj
end

function slib.usingDirectory(root_scripts_directory_path, loading_text, disable_auto_include)
	local files, directories = file.Find(root_scripts_directory_path .. '/*', 'LUA')
	local files_list = {}

	table.SortDesc(files)

	for _, file_path in ipairs(files) do
		table.insert(files_list, {
			file_path = file_path,
			file_type = GetFileNetworkType(file_path)
		})
	end

	local inc = slib.CreateIncluder(nil, loading_text)
	local return_values = {
		['cl'] = {},
		['sv'] = {},
		['sh'] = {},
	}

	for _, fileData in pairs(files_list) do
		local return_value = inc:using(root_scripts_directory_path .. '/' .. fileData.file_path, disable_auto_include)
		table.insert(return_values[fileData.file_type], return_value)
	end

	for _, directory_path in ipairs(directories) do
		local sub_return_values = slib.usingDirectory(root_scripts_directory_path .. '/' .. directory_path, loading_text)
		for key, table_value in pairs(sub_return_values) do
			table.Add(return_values[key], table_value)
		end
	end

	return return_values
end