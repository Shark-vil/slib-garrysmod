local slib = slib
local tostring = tostring
local util = util
--

local uid = 0
local uid_hash = 0

function slib.GetUid()
	uid = uid + 1
	return uid
end

function slib.GenerateUid( salt )
	salt = salt or ''
	uid_hash = uid_hash + 1
	return tostring( util.CRC( tostring( salt ) .. tostring( uid_hash ) ) )
end

function slib.GenerateUidHash( salt )
	salt = salt or ''
	uid_hash = uid_hash + 1
	return tostring( util.Base64Encode( tostring( salt ) .. tostring( uid_hash ) ) )
end