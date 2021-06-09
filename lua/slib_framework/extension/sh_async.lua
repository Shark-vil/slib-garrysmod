async = async or {}

local yield = coroutine.yield
local wait = coroutine.wait

function async.Add(id, func)
   async.Remove(id)

   local co, worked, value

   hook.Add('Think', 'slib_async_' .. id, function()      
      if not co or not worked then co = coroutine.create(func) end

      worked, value = coroutine.resume(co, yield, wait)

      if value == 'stop' then
         async.Remove(id)
      end
   end)
end

function async.Remove(id)
   hook.Remove('Think', 'slib_async_' .. id)
end