async = async or {}

function async.Add(id, func)
   async.Remove(id)

   local co
   hook.Add('Think', 'slib_async_' .. id, function()
      if not co or not coroutine.resume(co, coroutine.yield, coroutine.wait) then
         co = coroutine.create(func)
         coroutine.resume(co, coroutine.yield, coroutine.wait)
      end
   end)
end

function async.Remove(id)
   hook.Remove('Think', 'slib_async_' .. id)
end