local uid = 0
function slib.GenerateUid(salt)
   salt = salt or ''
   if not isstring(salt) then salt = tostring(salt) end
   uid = uid + 1
   return tostring(util.CRC(salt .. CurTime() .. uid))
end