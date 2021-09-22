local snet = slib.Components.Network
local TYPE_TABLE = TYPE_TABLE
local TYPE_NUMBER = TYPE_NUMBER
local TYPE_STRING = TYPE_STRING
local TYPE_BOOL = TYPE_BOOL
local TYPE_ENTITY = TYPE_ENTITY
local TYPE_VECTOR = TYPE_VECTOR
local TYPE_ANGLE = TYPE_ANGLE
local TYPE_MATRIX = TYPE_MATRIX
local TYPE_COLOR = TYPE_COLOR
local IsValid = IsValid
local IsColor = IsColor
local type = type
local istable = istable
local isfunction = isfunction
local pairs = pairs
local Entity = Entity
local Matrix = Matrix
local Color = Color
local Vector = Vector
local Angle = Angle
local table_insert = table.insert
local util_TableToJSON = util.TableToJSON
local util_JSONToTable = util.JSONToTable
--
local ValueSerialize = {
	[TYPE_TABLE] = function(t, v)
		local getdatatable = snet.Serialize(v, true)
		if getdatatable then return t, getdatatable end
	end,
	[TYPE_NUMBER] = function(t, v) return t, v end,
	[TYPE_STRING] = function(t, v) return t, v end,
	[TYPE_BOOL] = function(t, v) return t, v end,
	[TYPE_ENTITY] = function(t, v)
		if not v or not IsValid(v) then return end
		local index = v:EntIndex()
		if index == -1 then return end

		return t, index
	end,
	[TYPE_VECTOR] = function(t, v) return t, v:ToTable() end,
	[TYPE_ANGLE] = function(t, v) return t, v:ToTable() end,
	[TYPE_MATRIX] = function(t, v) return t, v:ToTable() end,
	[TYPE_COLOR] = function(t, v) return t, v:ToTable() end,
}

local function GetValueType(value)
	local typeid

	if IsColor(value) then
		typeid = TYPE_COLOR
	else
		typeid = TypeID(value)
	end

	return typeid
end

local function GetValueToCompress(k, v)
	local key_type, key_data, val_type, val_data, typeid, converter
	typeid = GetValueType(k)
	converter = ValueSerialize[typeid]

	if converter then
		key_type, key_data = converter(typeid, k)
		typeid = GetValueType(v)
		converter = ValueSerialize[typeid]

		if converter then
			val_type, val_data = converter(typeid, v)

			return {key_type, key_data, val_type, val_data,}
		end
	end

	return nil
end

function snet.Serialize(data, notcompress, fastparser)
	local datatable = {}

	if type(data) == 'table' and not data._snet_disable then
		if data._snet_getdata and isfunction(data._snet_getdata) then
			local getdata = data._snet_getdata()

			if istable(getdata) then
				datatable = getdata
			end
		else
			if fastparser then
				for k = 1, #data do
					local result = GetValueToCompress(k, data[k])

					if result then
						table_insert(datatable, result)
					end
				end
			else
				for k, v in pairs(data) do
					local result = GetValueToCompress(k, v)

					if result then
						table_insert(datatable, result)
					end
				end
			end
		end
	end

	if not notcompress then
		return util_TableToJSON(datatable)
	else
		return datatable
	end
end

local ValueDeserialize = {
	[TYPE_TABLE] = function(v)
		local getdatatable = snet.Deserialize(v)
		if getdatatable then return getdatatable end
	end,
	[TYPE_NUMBER] = function(v) return v end,
	[TYPE_STRING] = function(v) return v end,
	[TYPE_BOOL] = function(v) return v end,
	[TYPE_ENTITY] = function(v) return Entity(v) end,
	[TYPE_VECTOR] = function(v) return Vector(v[1], v[2], v[3]) end,
	[TYPE_ANGLE] = function(v) return Angle(v[1], v[2], v[3]) end,
	[TYPE_MATRIX] = function(v) return Matrix(v) end,
	[TYPE_COLOR] = function(v) return Color(v[1], v[2], v[3], v[4]) end,
}

function snet.Deserialize(json_datatable)
	local datatable = {}
	local t_type = type(json_datatable)
	local getdatatable

	if t_type == 'string' then
		getdatatable = util_JSONToTable(json_datatable)
	elseif t_type == 'table' then
		getdatatable = json_datatable
	else
		return datatable
	end

	for i = 1, #getdatatable do
		local key, value
		local data = getdatatable[i]

		do
			local deconverter = ValueDeserialize[data[1]]

			if deconverter then
				key = deconverter(data[2])
			end
		end

		if key ~= nil then
			local deconverter = ValueDeserialize[data[3]]

			if deconverter then
				value = deconverter(data[4])
				datatable[key] = value
			end
		end
	end

	return datatable
end

function snet.ValueIsValid(value)
	local typeid = TypeID(value)
	if typeid == TYPE_TABLE or typeid == TYPE_NUMBER or typeid == TYPE_STRING or typeid == TYPE_BOOL or typeid == TYPE_ENTITY or typeid == TYPE_VECTOR or typeid == TYPE_ANGLE or typeid == TYPE_MATRIX or typeid == TYPE_COLOR then return true end

	return false
end

function snet.GetNormalizeDataTable(data)
	local new_data = {}
	if not istable(data) then return new_data end
	if data._snet_disable then return new_data end

	if data._snet_getdata and isfunction(data._snet_getdata) then
		local getdata = data._snet_getdata()
		if istable(getdata) then return getdata end

		return new_data
	end

	for k, v in pairs(data) do
		if not snet.ValueIsValid(k) or not snet.ValueIsValid(v) then
			goto skip
		end

		if istable(v) then
			new_data[k] = snet.GetNormalizeDataTable(v)
		else
			new_data[k] = v
		end

		::skip::
	end

	return new_data
end