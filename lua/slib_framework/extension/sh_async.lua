local coroutine_yield = coroutine.yield
local coroutine_wait = coroutine.wait
local coroutine_create = coroutine.create
local coroutine_resume = coroutine.resume
local table_remove = table.remove
local table_insert = table.insert
local hook = slib.Component('Hook')
local registred_async_process = {}
local registred_async_process_self_container = {}
local registred_async_process_count = 0
local registred_async_process_self_container_count = 0
--
async = async or {}

local function async_execute(obj)
	local id = obj.id
	local func = obj.func
	local co = obj.co
	local worked = obj.worked
	local value = obj.value

	if not co or not worked then
		co = coroutine_create(func)
	end

	worked, value = coroutine_resume(co, coroutine_yield, coroutine_wait)

	obj.value = value
	obj.worked = worked
	obj.co = co

	if value == 'stop' then
		slib.DebugLog('Async process "' .. id .. '" is stopped')
		async.Remove(id)
		return
	end

	if not worked and value ~= 'cannot resume dead coroutine' then
		slib.Warning('\n[ASYNC ERROR] ' .. id .. ':\n' .. tostring(value) .. '\r')
	end
end

do
	local current_index = 0

	hook.Add('Think', 'slib.system.async_process_handler', function()
		if registred_async_process_count == 0 then return end

		current_index = current_index + 1

		if current_index < 1 or current_index > registred_async_process_count then
			current_index = 1
		end

		local obj = registred_async_process[current_index]
		if not obj then return end

		async_execute(obj)

		slib.DebugLog('Current asynchronous process - ', obj.id, ' [', obj.uuid, ']')
	end)
end

function async.Add(id, func, self_hook)
	async.Remove(id)

	local value = {
		id = id,
		uuid = slib.UUID(),
		func = func,
		co = nil,
		worked = false,
		value = nil
	}

	if self_hook then
		local index = table_insert(registred_async_process_self_container, value)
		local obj = registred_async_process_self_container[index]

		hook.Add('Think', 'slib.system.async_process_handler.' .. value.uuid, function()
			async_execute(obj)
		end)

		slib.DebugLog('Added independent asynchronous process - ', value.id, ' [', value.uuid, ']')
	else
		table_insert(registred_async_process, value)

		slib.DebugLog('Added asynchronous process - ', value.id, ' [', value.uuid, ']')
	end

	registred_async_process_count = #registred_async_process
	registred_async_process_self_container_count = #registred_async_process_self_container
end

function async.AddDedic(id, func)
	async.Add(id, func, true)
end

function async.Exists(id)
	for i = registred_async_process_count, 1, -1 do
		if registred_async_process[i].id == id then return true end
	end

	for i = registred_async_process_self_container_count, 1, -1 do
		if registred_async_process_self_container[i].id == id then return true end
	end

	return false
end

function async.Remove(id)
	for i = registred_async_process_count, 1, -1 do
		local obj = registred_async_process[i]
		if obj.id ~= id then continue end
		table_remove(registred_async_process, i)
		break
	end

	for i = registred_async_process_self_container_count, 1, -1 do
		local obj = registred_async_process_self_container[i]
		if obj.id ~= id then continue end
		hook.Remove('Think', 'slib.system.async_process_handler.' .. obj.uuid)
		table_remove(registred_async_process, i)
		break
	end

	registred_async_process_count = #registred_async_process
	registred_async_process_self_container_count = #registred_async_process_self_container
end