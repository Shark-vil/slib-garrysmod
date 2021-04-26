-- local original_include = include

-- local function optimizator(file_path)
--    local file, _ = io.open(file_path, "r")
--    if not file then return end

--    local source = file:read("*all")
--    file:close()
--    if not source then return end

--    print(file_path, ' - ', #source)
-- end

-- function optimize_include(name)
--    local found_path = debug.getinfo(2, "S").source
--    assert(found_path:sub(1, 1) == "@")
--    local path = found_path:sub(2):gsub("/[^/]*$", "")
--    local full_path = path .. "/" .. name
--    optimizator(full_path)
--    return original_include(name)
-- end