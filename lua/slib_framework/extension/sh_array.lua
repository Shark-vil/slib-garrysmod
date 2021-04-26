array = array or {}

function array.isArray(t)
   local past_value_type

   for key, value in next, t do
      if type(key) ~= 'number' then return false end

      local value_type = type(value)

      if past_value_type == nil then
         past_value_type = value_type
      elseif value_type ~= past_value_type then
         return false
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

function array.WhereHasValue(t, condition)
   for i = 1, #t do
      if condition(i, t[i]) then return true end
   end
   return false
end

function array.Find(t, find_value)
   for i = 1, #t do
      local value = t[i]
      if find_value == value then return i, value end
   end
   return -1, nil
end

function array.WhereFind(t, condition)
   for i = 1, #t do
      local value = t[i]
      if condition(i, value) then return i, value end
   end
   return -1, nil
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
   local count = #t
   if count == 0 then return nil end
   return t[ math.random( count ) ]
end

function array.RandomOmit(t, v)
   if v == nil then return array.Random(t) end

   local count = #t
   if count == 0 then return nil end
   if count == 1 then
      local first_value = t[1]
      if first_value == v then return nil end
      return first_value
   end

   local random_value = v
   repeat
      random_value = array.Random(t)
   until random_value ~= v

   return random_value
end

function array.insert(t, v)
   t[ #t + 1 ] = v
end

function array.remove(t, index)
   table.remove(t, index)
end

function array.RemoveByValue(t, v)
   for i = #t, 1, -1 do
      if t[i] == v then
         t[i] = nil
         return true
      end
   end
   return false
end

function array.RemoveAllByValue(t, v)
   for i = #t, 1, -1 do
      if t[i] == v then t[i] = nil end
   end
end

function array.RemoveLastValue(t)
   table.remove(t, #t)
end

function array.RemoveFirstValue(t)
   table.remove(t, 1)
end