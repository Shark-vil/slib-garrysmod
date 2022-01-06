local coroutine_yield = coroutine.yield
local coroutine_wait = coroutine.wait
local coroutine_create = coroutine.create
local coroutine_resume = coroutine.resume
--
async = async or {}

function async.Add(id, func)
	async.Remove(id)
	local co, worked, value

	hook.Add('Think', 'slib_async_' .. id, function()
		if not co or not worked then
			co = coroutine_create(func)
		end

		worked, value = coroutine_resume(co, coroutine_yield, coroutine_wait)

		-- if value == 'stop' or (not worked and value == 'cannot resume dead coroutine') then
		-- 	slib.DebugLog('Async process "' .. id .. '" is stopped')
		-- 	async.Remove(id)
		-- 	return
		-- end

		if value == 'stop' then
			slib.DebugLog('Async process "' .. id .. '" is stopped')
			async.Remove(id)
			return
		end

		if not worked and value ~= 'cannot resume dead coroutine' then
			ErrorNoHalt('\n[SLIB][ASYNC ERROR] ' .. id .. ':\n' .. value .. '\r')
		end
	end)
end

function async.Exists(id)
	return hook.Get('Think', 'slib_async_' .. id) ~= nil
end

function async.Remove(id)
	hook.Remove('Think', 'slib_async_' .. id)
end