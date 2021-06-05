async = async or {}

local yield = coroutine.yield
local wait = coroutine.wait

function async.Add(id, func)
   async.Remove(id)

   local co, worked, is_repeat

   hook.Add('Think', 'slib_async_' .. id, function()
      if not co or not worked then co = coroutine.create(func) end

      worked, is_repeat = coroutine.resume(co, yield, wait)

      if not worked and not is_repeat then
         async.Remove(id)
         return
      end
   end)
end

function async.Remove(id)
   hook.Remove('Think', 'slib_async_' .. id)
end