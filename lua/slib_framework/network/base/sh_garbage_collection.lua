local slib = slib
local snet = slib.Components.Network
local RealTime = RealTime
local table_remove = table.remove
local xpcall = xpcall
local pairs = pairs
local Warning = slib.Warning
local Error = slib.Error

function snet.RunGarbageCollection(requests)
  local counting_requests = {}

  for i = #requests, 1, -1 do
    local data = requests[i]
    if not data or (data.request and not data.request.eternal and data.timeout < RealTime()) then
      if data and data.request and data.request.func_complete then
        xpcall(function()
          data.request.func_complete(data.receiver, data)
        end, function(error_message)
          Error('Failed to complete the request due to an error')
          Error('NETWORK ERROR:\n' .. error_message)
        end)
      end
      table_remove(requests, i)
    end

    if data and data.request then
      local request_name = data.request.name
      counting_requests[request_name] = counting_requests[request_name] or 0
      counting_requests[request_name] = counting_requests[request_name] + 1
    end
  end

  local count = #requests
  if count >= 500 then
    Warning('Something is making too many requests (' .. count .. ')')
    for k, v in pairs(counting_requests) do
      Warning('COUNTING REQUEST: ' .. k .. ' - ' .. v)
    end
  end
end