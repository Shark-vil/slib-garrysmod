local CLASS = {}

function CLASS:Instance()
	local private = {}
	private.table_name = nil
	private.table_model = nil
	private.sql_create_table = nil
	private.base64_fields = {}
	private.compressed_fields = {}

	local public = {}

	function public:SetModel(table_name, table_model)
		private.table_name = table_name
		private.table_model = table_model

		local fields = {}
		local foreign_keys = {}

		for index, struct in ipairs(table_model) do
			local field = ''

			if struct.name and not struct.foreign_key then
				field = struct.name

				if struct.base64 or struct.compress then
					private.base64_fields[field] = true
					if struct.compress then
						table_model[index].base64 = true
						private.compressed_fields[field] = true
					end
				end

				local value_type = string.lower(struct.type)

				if value_type == 'int'
					or value_type == 'integer'
					or value_type == 'number'
					or value_type == 'numberic'
				then
					field = field .. ' ' .. 'INTEGER'
				elseif value_type == 'boolean'
					or value_type == 'bool'
					or value_type == 'numberic'
				then
					field = field .. ' ' .. 'INTEGER'
				elseif value_type == 'str'
					or value_type == 'string'
					or value_type == 'text'
				then
					field = field .. ' ' .. 'TEXT'
				elseif value_type == 'varchar' then
					local value = 255
					if struct.value and isnumber(struct.value) then value = struct.value end
					field = field .. ' ' .. 'VARCHAR(' .. value .. ')'
				end

				if struct.primary_key then
					field = field .. ' ' .. 'PRIMARY KEY'
					if struct.auto  then
						field = field .. ' ' .. 'AUTOINCREMENT'
					end
				end

				fields[#fields + 1] = field
			elseif struct.foreign_key then
				local foreign_key = struct.foreign_key
				local name = foreign_key.name
				local key = foreign_key.key
				local reference = foreign_key.reference
				field = 'FOREIGN KEY (' .. name .. ') REFERENCES ' .. reference .. ' (' .. key .. ')'

				foreign_keys[#foreign_keys + 1] = field
			end
		end

		private.sql_create_table = 'CREATE TABLE IF NOT EXISTS ' .. table_name .. ' (\n'

		do
			local count = #fields
			for i = 1, count do
				if count == i then
					private.sql_create_table = private.sql_create_table  .. fields[i] .. '\n'
				else
					private.sql_create_table = private.sql_create_table  .. fields[i] .. ',\n'
				end
			end
		end

		for i = 1, #foreign_keys do
			private.sql_create_table = private.sql_create_table .. fields[i] .. '\n'
		end

		private.sql_create_table = private.sql_create_table .. ')'
	end

	function public:GetSqlModel()
		return private.sql_create_table
	end

	function public:SetSqlModel(sql_model)
		private.sql_create_table = sql_model
	end

	function public:MakeTable()
		if not private.sql_create_table then return end
		return sql.Query(private.sql_create_table)
	end

	function public:DropTable()
		if not private.sql_create_table then return end
		return sql.Query('DROP TABLE ' .. private.table_name)
	end

	function public:ResetTable()
		self:DropTable()
		self:MakeTable()
	end

	function public:Insert(insert_data)
		local query = 'INSERT INTO ' .. private.table_name
		local insert_keys = ''
		local insert_values = ''
		local count = #insert_data.fields

		for index = 1, count do
			local field = insert_data.fields[index]
			if private.base64_fields[field.name] then
				if private.compressed_fields[field.name] then
					field.value = util.Compress(field.value)
				end
				field.value = util.Base64Encode(field.value)
			end

			if index ~= 1 then
				insert_keys = insert_keys .. field.name
				insert_values = insert_values .. ' "' .. field.value .. '"'
			else
				insert_keys = field.name
				insert_values = '"' .. field.value .. '"'
			end

			if count ~= index then
				insert_keys = insert_keys .. ','
				insert_values = insert_values .. ','
			end
		end

		query = query .. '(' .. insert_keys .. ') VALUES(' .. insert_values .. ')'

		return sql.Query(query)
	end

	function public:Update(update_data)
		local query = 'UPDATE ' .. private.table_name .. ' SET '
		local count = #update_data.fields

		for index = 1, count do
			local field = update_data.fields[index]
			if private.base64_fields[field.name] then
				if private.compressed_fields[field.name] then
					field.value = util.Compress(field.value)
				end
				field.value = util.Base64Encode(field.value)
			end

			query = query .. field.name .. ' = "' .. field.value .. '"'

			if count ~= index then
				query = query .. ', '
			end
		end

		if update_data.where then
			local where = update_data.where
			query = query .. ' WHERE ' .. where.name .. ' = "' .. where.value .. '"'
		end

		if update_data.first then
			update_data.limit = 1
		end

		if update_data.limit then
			query = query .. ' LIMIT ' .. update_data.limit
		end

		if update_data.offset then
			query = query .. ' OFFSET ' .. update_data.offset
		end

		return sql.Query(query)
	end

	function public:InsertOrUpdate(insert_or_update_data)
		local read_data = self:Read(insert_or_update_data)
		if not read_data then
			return self:Insert(insert_or_update_data)
		else
			local fields = insert_or_update_data.fields
			for i = 1, #read_data do
				for k, v in pairs(read_data[i]) do
					for j = 1, #fields do
						if fields[j].name == k and fields[j].value ~= v then
							return self:Update(insert_or_update_data)
						end
					end
				end
			end
		end
	end

	function public:Read(read_data)
		local query = 'SELECT '
		local fileds = ''
		read_data.fields = read_data.fields or {}
		local fields_count =  #read_data.fields

		if fields_count == 0 then
			fileds = '*'
		else
			for i = 1, fields_count do
				local value = read_data.fields[i]
				local name = value.name

				fileds = fileds .. name
				if i ~= fields_count then
					fileds = fileds .. ', '
				end
			end
		end

		query = query .. fileds .. ' FROM ' .. private.table_name

		if read_data.where then
			local where = read_data.where
			query = query .. ' WHERE ' .. where.name .. ' = "' .. where.value .. '"'
		end

		if read_data.first then
			read_data.limit = 1
		end

		if read_data.limit then
			query = query .. ' LIMIT ' .. read_data.limit
		end

		if read_data.offset then
			query = query .. ' OFFSET ' .. read_data.offset
		end

		local result = sql.Query(query)
		if result then
			for i = 1, #result do
				local row = result[i]
				local new_row = row

				for key, value in pairs(row) do
					if private.base64_fields[key] then
						new_row[key] = util.Base64Decode(value)
						if private.compressed_fields[key] then
							new_row[key] = util.Decompress(new_row[key])
						end
					end
				end

				result[i] = new_row
			end

			if read_data.first then return result[1] end
			return result
		end
	end

	return public
end

slib.SetComponent('SQL', CLASS)