slib.ProfilerCreate = function()
   local obj = {}
   obj.lastTick = 0
   obj.ticks = {}

   function obj:Start()
      self.lastTick = SysTime()
   end

   function obj:End()
      table.insert(self.ticks, SysTime() - self.lastTick)
   end

   function obj:Complete()
      local summ = 0
      for _, time in ipairs(self.ticks) do
         summ = summ + time
      end
      return summ / #self.ticks
   end

   return obj
end