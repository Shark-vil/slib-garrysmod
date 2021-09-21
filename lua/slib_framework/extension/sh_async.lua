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

		if value == 'stop' then
			async.Remove(id)
		end
	end)
end

function async.Remove(id)
	hook.Remove('Think', 'slib_async_' .. id)
end