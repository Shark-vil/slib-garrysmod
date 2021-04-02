local ValueSerialize = {
   [TYPE_TABLE] = function(t, v)
      local getdatatable = snet.Serialize(v, true)
      if getdatatable then
         return t, getdatatable
      end
   end,
   [TYPE_NUMBER] = function(t, v)
      return t, v
   end,
   [TYPE_STRING] = function(t, v)
      return t, v
   end,
   [TYPE_BOOL] = function(t, v)
      return t, v
   end,
   [TYPE_ENTITY] = function(t, v)
      if not v or not IsValid(v) then return end

      local index = v:EntIndex()
      if index == -1 then return end

      return t, index
   end,
   [TYPE_VECTOR] = function(t, v)
      return t, v:ToTable()
   end,
   [TYPE_ANGLE] = function(t, v)
      return t, v:ToTable()
   end,
   [TYPE_MATRIX] = function(t, v)
      return t, v:ToTable()
   end,
   [TYPE_COLOR] = function(t, v)
      return t, v:ToTable()
   end,
}

local function GetValueType(value)
   local typeid
   if IsColor(value) then typeid = TYPE_COLOR else typeid = TypeID(value) end
   return typeid
end

function snet.Serialize(data, notcompress)
   local datatable = {}

   if istable(data) and not data._snet_disable then
      if data._snet_getdata and isfunction(data._snet_getdata) then
         local getdata = data._snet_getdata()
         if istable(getdata) then datatable = getdata end
      else
         for k, v in pairs(data) do
            local key_type, key_data, val_type, val_data

            do
               local typeid = GetValueType(k)
               local converter = ValueSerialize[typeid]
               if converter then 
                  key_type, key_data = converter(typeid, k)
               end
            end

            if key_type ~= nil and key_data ~= nil then
               do
                  local typeid = GetValueType(v)
                  local converter = ValueSerialize[typeid]
                  if converter then 
                     val_type, val_data = converter(typeid, v)
                     table.insert(datatable, {
                        key_type, key_data,
                        val_type, val_data,
                     })
                  end
               end
            end
         end
      end
   end

   local notcompress = notcompress or false
   if not notcompress then
      return util.TableToJSON(datatable)
   else
      return datatable
   end
end

local ValueDeserialize = {
   [TYPE_TABLE] = function(v)
      local getdatatable = snet.Deserialize(v)
      if getdatatable then
         return getdatatable
      end
   end,
   [TYPE_NUMBER] = function(v)
      return v
   end,
   [TYPE_STRING] = function(v)
      return v
   end,
   [TYPE_BOOL] = function(v)
      return v
   end,
   [TYPE_ENTITY] = function(v)
      return Entity(v)
   end,
   [TYPE_VECTOR] = function(v)
      return Vector(v[1], v[2], v[3])
   end,
   [TYPE_ANGLE] = function(v)
      return Angle(v[1], v[2], v[3])
   end,
   [TYPE_MATRIX] = function(v)
      return Matrix(v)
   end,
   [TYPE_COLOR] = function(v)
      return Color(v[1], v[2], v[3], v[4])
   end,
}

function snet.Deserialize(json_datatable)
   local datatable = {}
   local t_type = type(json_datatable) 
   local getdatatable

   if t_type == 'string' then
      getdatatable = util.JSONToTable(json_datatable)
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
   if typeid == TYPE_TABLE or typeid == TYPE_NUMBER
   or typeid == TYPE_STRING or typeid == TYPE_BOOL
   or typeid == TYPE_ENTITY or typeid == TYPE_VECTOR
   or typeid == TYPE_ANGLE or typeid == TYPE_MATRIX
   or typeid == TYPE_COLOR
   then
      return true
   end
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
		if not snet.ValueIsValid(k) or not snet.ValueIsValid(v) then goto skip end

		if istable(v) then
			new_data[k] = snet.GetNormalizeDataTable(v)
		else
			new_data[k] = v
		end

		::skip::
	end

	return new_data
end