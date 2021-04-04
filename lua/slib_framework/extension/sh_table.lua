function table.IHasValue(t, val)
   for i = 1, #t do
      if t[i] == val then return true end
   end
   return false
end