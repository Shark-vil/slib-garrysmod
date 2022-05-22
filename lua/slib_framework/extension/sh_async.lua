local coroutine_yield = coroutine.yield
local coroutine_wait = coroutine.wait
local coroutine_create = coroutine.create
local coroutine_resume = coroutine.resume
local hook = slib.Component('Hook')
local registred_async_process = {}
--
async = async or {}

hook.Add('Think', 'slib_async_process_handler', function()
	for i = #registred_async_process, 1, -1 do
		local obj = registred_async_process[i]
		if not obj then continue end

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
			continue
		end

		if not worked and value ~= 'cannot resume dead coroutine' then
			slib.Warning('\n[ASYNC ERROR] ' .. id .. ':\n' .. tostring(value) .. '\r')
		end
	end
end)

function async.Add(id, func)
	async.Remove(id)

	table.insert(registred_async_process, {
		id = id,
		func = func,
		co = nil,
		worked = false,
		value = nil,
	})
end

function async.Exists(id)
	for i = #registred_async_process, 1, -1 do
		if registred_async_process[i].id == id then return true end
	end
	return false
end

function async.Remove(id)
	for i = #registred_async_process, 1, -1 do
		if registred_async_process[i].id == id then
			table.remove(registred_async_process, i)
			break
		end
	end
end