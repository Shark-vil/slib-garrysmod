slib = slib or {}
snet = snet or net

local root_directory = 'slib_framework'

local function p_include(file_path)
	include(file_path)
	MsgN('[SLIB] Script load - ' .. file_path)
end

local function using(local_file_path, network_type, not_root_directory)
	local file_path = local_file_path

	if not not_root_directory then
		file_path = root_directory .. '/' .. local_file_path
	end

	network_type = network_type or string.sub(string.GetFileFromFilename(local_file_path), 1, 2)
	network_type = string.lower(network_type)

	if network_type == 'cl' or network_type == 'sh' then
		if SERVER then AddCSLuaFile(file_path) end
		if CLIENT and network_type == 'cl' then
			p_include(file_path)
		elseif network_type == 'sh' then
			p_include(file_path)
		end
	elseif network_type == 'sv' and SERVER then
		p_include(file_path)
	end
end

using('network/sh_addnetwork.lua')
using('network/sh_callback.lua')
using('network/sh_validator.lua')
using('network/sh_entity_callback.lua')

using('override/entity/sh_entity.lua')
using('override/entity/sv_entity.lua')
using('override/entity/cl_entity.lua')

-- using('override/player/sh_player.lua')

using('cvars/gcvars/sh_gcvars.lua')
using('cvars/gcvars/sv_gcvars.lua')
using('cvars/gcvars/cl_gcvars.lua')

using('hooks/sh_player_first_spawn.lua')

using('extension/sh_player.lua')