slib = slib or {}
snet = snet or net
snet.storage = {}

local root_directory = 'slib_framework'

if SERVER then
	AddCSLuaFile(root_directory .. '/extension/sh_script_include.lua')
end
include(root_directory .. '/extension/sh_script_include.lua')

local script = slib.CreateIncluder(root_directory, '[SLibrary] Script load - {file}')

script:using('network/sh_addnetwork.lua')
script:using('network/sh_serializator.lua')
script:using('network/sh_callback.lua')
script:using('network/validator/sh_validator.lua')
script:using('network/validator/sh_validator_server.lua')
script:using('network/validator/sh_validator_client.lua')
script:using('network/entity/sh_entity_callback.lua')

script:using('network/bigdata/sh_callback_bigdata.lua')
script:using('network/bigdata/server/sv_init_networkstring.lua')
script:using('network/bigdata/server/sv_processing.lua')
script:using('network/bigdata/server/sv_ok_or_error.lua')
script:using('network/bigdata/client/cl_processing.lua')
script:using('network/bigdata/client/cl_ok_or_error.lua')

script:using('override/entity/sh_entity.lua')
script:using('override/entity/sv_entity.lua')
script:using('override/entity/cl_entity.lua')

script:using('override/player/sh_player.lua')
script:using('override/player/sv_player.lua')
script:using('override/player/cl_player.lua')

script:using('cvars/gcvars/sh_gcvars.lua')
script:using('cvars/gcvars/sv_gcvars.lua')
script:using('cvars/gcvars/cl_gcvars.lua')

script:using('hooks/sh_player_first_spawn.lua')

script:using('extension/sh_generators.lua')
script:using('extension/sh_player.lua')
script:using('extension/sh_table.lua')
script:using('extension/sh_sound_duration.lua')

script:using('debug/sh_profiler.lua')

-- To connect scripts that depend on the library
slib.usingDirectory('slib_autoloader')