table = table or {}

function table.FastHasValue(t, v)
   return array.HasValue(t, v)
end

function table.WhereHasValue(t, condition)
   for k, v in next, t do
      if condition(k, v) then return true end
   end
   return false
end

function table.Find(t, find_value)
   for k, v in next, t do
      if find_value == v then return k, v end
   end
   return -1, nil
end

function table.WhereFind(t, condition)
   for k, v in next, t do
      if condition(k, v) then return k, v end
   end
   return -1, nil
end

function table.equals(t1, t2)
   if type(t1) ~= 'table' or type(t2) ~= 'table' then return false end

   for k, v in next, t1 do
      if type(v) == 'table' then
         if not table.equals(v, t2[k]) then return false end
      elseif v ~= t2[k] then
         return false
      end
   end

   return true
end