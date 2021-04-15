function array.IsArray(t)
   local past_key_type
   local past_value_type

   for key, value in next, t do
      local key_type = type(key)
      local value_type = type(value)

      if past_key_type == nil and past_value_type == nil then
         past_key_type = key_type
         past_value_type = value_type
      else
         if key_type ~= past_key_type or value_type ~= past_value_type then return false end
      end
   end

   return true
end

function array.HasValue(t, val)
   for i = 1, #t do
      if t[i] == val then return true end
   end
   return false
end

function array.shuffle(t)
   local tbl = {}
   for i = 1, #t do
      tbl[i] = t[i]
   end

   for i = #tbl, 2, -1 do
      local j = math.random(i)
      tbl[i], tbl[j] = tbl[j], tbl[i]
   end
   return tbl
end

function array.Random(t)
   return t[ math.random(#t) ]
end

function array.RandomOmit(t, v)
   if v == nil then return array.Random(t) end

   local count = #t
   if count == 0 then return nil end
   if count == 1 then return t[1] end

   local random_value = v
   repeat
      random_value = array.Random(t)
   until random_value ~= v

   return random_value
end