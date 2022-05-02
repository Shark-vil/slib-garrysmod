local coroutine_yield = coroutine.yield
local coroutine_wait = coroutine.wait
local coroutine_create = coroutine.create
local coroutine_resume = coroutine.resume
--
slib.ThinkQueue = slib.ThinkQueue or {}

local async_functions = {}
local async_functions_count = 0
local current_async_think = 1

function slib.ThinkQueue.Add(id, func)
	slib.ThinkQueue.Remove(id)

	table.insert(async_functions, { id = id, func = func, co = nil })
	async_functions_count = #async_functions
end

function slib.ThinkQueue.Exists(id)
	for i = 1, #async_functions do
		local v = async_functions[i]
		if v.id == id then return true end
	end

	return false
end

function slib.ThinkQueue.Remove(id)
	for i = 1, #async_functions do
		local v = async_functions[i]
		if v.id == id then
			table.remove(async_functions, k)
			break
		end
	end

	async_functions_count = #async_functions
end

local async_call_max_pass = 100
local async_call_current_pass = 0

hook.Add('Think', 'slib_async_think_queue', function()
	if async_functions_count == 0 then return end

	if current_async_think > async_functions_count then
		current_async_think = 1
	end

	local async_data = async_functions[current_async_think]
	local co

	if async_data then
		local func = async_data.func
		co = async_data.co

		if not co or not worked then co = coroutine_create(func) end
		async_data.co = co

		worked, value = coroutine_resume(co, coroutine_yield, coroutine_wait)
		if value == 'stop' then async.Remove(id) end
	end

	if not co or coroutine.status(co) == 'suspended' then
		current_async_think = current_async_think + 1
	else
		async_call_current_pass = async_call_current_pass + 1
		if async_call_current_pass > async_call_max_pass then
			current_async_think = current_async_think + 1
			async_call_current_pass = 0
		end
	end
end)