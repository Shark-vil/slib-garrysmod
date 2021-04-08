function table.IHasValue(t, val)
   for i = 1, #t do
      if t[i] == val then return true end
   end
   return false
end

function table.shuffle(t)
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