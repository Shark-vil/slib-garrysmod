local util_MD5 = util.MD5
local util_Compress = util.Compress
local util_Decompress = util.Decompress
local file_Exists = file.Exists
local file_Write = file.Write
local file_Append = file.Append
local file_Read = file.Read
local file_CreateDir = file.CreateDir
local string_GetPathFromFilename = string.GetPathFromFilename
local string_GetFileFromFilename = string.GetFileFromFilename
local tostring = tostring
local type = type
--

function slib.FileStream(file_path, compressed_data, dynamic_writer)
	-- if not slib.FileExists(file_path, 'DATA') then return end

	local private = {}
	private.has_open = false
	private.dynamic_writer = dynamic_writer or false
	private.compressed_data = compressed_data or false
	private.file_data = nil

	function private.GetWriteData(specific_string)
		local write_data_text = specific_string or private.file_data or ''
		if private.compressed_data then
			write_data_text = util_Compress(write_data_text)
		end
		return write_data_text
	end

	function private.WriteData(append_string)
		local directory_path = string_GetPathFromFilename(file_path)
		if not file_Exists(directory_path, 'DATA') then
			file_CreateDir(directory_path)
		end

		if not private.compressed_data and append_string and file_Exists(file_path, 'DATA') then
			file_Append(file_path, private.GetWriteData(append_string))
		else
			file_Write(file_path, private.GetWriteData(private.file_data))
		end
	end

	function private.ReadData()
		local read_data_text = ''
		if file_Exists(file_path, 'DATA') then
			read_data_text = file_Read(file_path, 'DATA')
			if private.compressed_data then return util_Decompress(read_data_text) end
		end
		return read_data_text
	end

	function private.DynamicWriter(append_string)
		if private.dynamic_writer then
			private.WriteData(append_string)
		end
	end

	function private.NormalizeString(...)
		local result_string = ''
		local arguments = { ... }
		for i = 1, #arguments do
			local text = arguments[i]
			if type(text) ~= 'string' then
				result_string = result_string .. tostring(text)
			else
				result_string = result_string .. text
			end
		end
		return result_string
	end

	local public = {}
	public.file_path = file_path
	public.file_name = string_GetFileFromFilename(file_path)
	public.directory_path = string_GetPathFromFilename(file_path)

	function public.Open()
		if private.has_open then return end
		private.has_open = true
		private.file_data = private.ReadData()
	end

	function public.Write(...)
		if not private.has_open then return end
		local text = private.NormalizeString(...)
		if util_MD5(private.file_data) == util_MD5(text) then return end
		private.file_data = text
		private.DynamicWriter()
	end

	function public.WriteLine(...)
		if not private.has_open then return end
		local text = private.NormalizeString(...)
		if #private.file_data ~= 0 then text = '\n' .. text end
		private.file_data = private.file_data .. text
		private.DynamicWriter(text)
	end

	function public.Append(...)
		if not private.has_open then return end
		local text = private.NormalizeString(...)
		private.file_data = private.file_data .. text
		private.DynamicWriter()
	end

	function public.Clear()
		if not private.has_open then return end
		private.file_data = ''
		private.DynamicWriter()
	end

	function public.Read()
		return private.file_data
	end

	function public.LinePairs()
		if not private.has_open then
			return function() end
		end

		return slib.StringLinePairs(private.file_data)
	end

	function public.HasOpen()
		return private.has_open
	end

	function public.Close()
		if not private.has_open or private.dynamic_writer then return end
		private.WriteData()
		private.has_open = false
		private.file_data = nil
	end

	if private.dynamic_writer then
		public.Open()
	end

	return public
end