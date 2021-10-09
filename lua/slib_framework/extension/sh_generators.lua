local tostring = tostring
local util_CRC = util.CRC
local util_Base64Encode = util.Base64Encode
local math_random = math.random
local uuid_template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
local string_gsub = string.gsub
local string_format = string.format
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
	return tostring( util_CRC( tostring( salt ) .. tostring( uid_hash ) ) )
end

function slib.GenerateUidHash( salt )
	salt = salt or ''
	uid_hash = uid_hash + 1
	return tostring( util_Base64Encode( tostring( salt ) .. tostring( uid_hash ) ) )
end

-- Source:
-- https://gist.github.com/jrus/3197011
function slib.UUID()
	return string_gsub(uuid_template, '[xy]', function (c)
		local v = (c == 'x') and math_random(0, 0xf) or math_random(8, 0xb)
		return string_format('%x', v)
	end)
end