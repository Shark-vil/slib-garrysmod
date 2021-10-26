slib = slib or {}
slib.Version = '1.4.3'

local root_directory = 'slib_framework'

if SERVER then
	AddCSLuaFile(root_directory .. '/core/base/sh_base.lua')
end
include(root_directory .. '/core/base/sh_base.lua')

local script = slib.CreateIncluder(root_directory, '[SLibrary] Script load - {file}')

script:using('core/base/sh_global.lua')
script:using('core/sh_components.lua')
script:using('core/sh_storage.lua')
script:using('core/sh_access.lua')

script:using('debug/sh_profiler.lua')
script:using('debug/sh_message.lua')

script:using('network/sh_base_params.lua')
script:using('network/sh_addnetwork.lua')
script:using('network/sh_serializator.lua')
script:using('network/base/sv_nethooks.lua')
script:using('network/base/callback/sh_callback.lua')
script:using('network/base/request/sh_request.lua')
script:using('network/base/request/sh_request_simple.lua')
script:using('network/base/sh_handler.lua')
script:using('network/base/backward/sv_backward.lua')
script:using('network/base/backward/cl_backward.lua')
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

script:using('network/file/sv_netfile_reader.lua')
script:using('network/file/cl_netfile_reader.lua')
script:using('network/file/cl_netfile_writer.lua')
script:using('network/file/sv_netfile_writer.lua')
script:using('network/file/cl_netfile_remover.lua')
script:using('network/file/sv_netfile_remover.lua')

script:using('override/entity/sh_entity.lua')
script:using('override/entity/sv_entity.lua')
script:using('override/entity/cl_entity.lua')

script:using('override/player/sh_player.lua')
script:using('override/player/sv_player.lua')
script:using('override/player/cl_player.lua')

script:using('override/vgui/cl_vgui.lua')

script:using('cvars/gcvars/sh_gcvars.lua')
script:using('cvars/gcvars/sv_gcvars.lua')
script:using('cvars/gcvars/cl_gcvars.lua')

script:using('commands/gcommands/sh_gcommands.lua')

script:using('hooks/sh_player_first_spawn.lua')

script:using('extension/sh_debug.lua')
script:using('extension/sh_fakeplayer.lua')
script:using('extension/sh_function_type.lua')
script:using('extension/sh_generators.lua')
script:using('extension/sh_player.lua')
script:using('extension/sh_array.lua')
script:using('extension/sh_sound_duration.lua')
script:using('extension/sh_file.lua')
script:using('extension/sh_hook.lua')
script:using('extension/sh_table.lua')
script:using('extension/sh_async.lua')
script:using('extension/sh_entity.lua')
script:using('extension/sh_hash.lua')
script:using('extension/sh_cvars.lua')
script:using('extension/sh_helpers.lua')
script:using('extension/gui/cl_helpers.lua')
script:using('extension/gui/cl_listener.lua')
script:using('extension/gui/cl_extension.lua')
script:using('extension/gui/cl_default_listeners.lua')
script:using('extension/gui/sh_routes.lua')
-- script:using('extension/sh_script_optimization.lua')

-- To connect scripts that depend on the library
slib.usingDirectory('slib_autoloader')

SLibraryIsLoaded = true