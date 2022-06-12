slib.Nodegraph = slib.Nodegraph or {}

function slib.Nodegraph:Read(map_name)
	map_name = map_name or game.GetMap()

	local file_path = 'maps/graphs/' .. map_name .. '.ain'
	if not file.Exists(file_path, 'GAME') then return end

	-- local fl = file.Open(file_path, 'rb', 'GAME')
end