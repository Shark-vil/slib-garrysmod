local uid = 0

function slib.GetUid()
	uid = uid + 1
	return uid
end

function slib.GenerateUid(salt)
	salt = salt or ''
	if not isstring(salt) then salt = tostring(salt) end
	return tostring(util.CRC(salt .. slib.GetUid()))
end