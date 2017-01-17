require("scripts/instance")

--[[ event ]
Inherits: instance

Description: Allows the option to add 'hooks' and be fired all at once.

Functions:
	nil fire( - Fires all connected hooks.
		instance source, - The source of the event.
		... - Passed parameters.
	)
	hook connect( - Connects a hook to this event.
		function func - callback function to be executed everytime 'fire' is called.
	) - returns a hook object.
	nil disconnect( - disconnects a hook from this event.
		hook hook - hook object.
	)
]]
local event = instance:class("event",{
	fire = function(self,...)
		if not self.hook then
			self.hook = {}
		end
		for k,v in pairs(self.hook) do
			if v then
				k:fire(...)
			else self.hook[k] = nil
			end
		end
	end,
	connect = function(self,func)
		if not self.hook then
			self.hook = {}
		end
		local v = instance:new("hook")
		v.event = self
		v.func = func
		self.hook[v] = true

		return v
	end,
	disconnect = function(self,hook)
		if not self.hook then
			self.hook = {}
		end
		if self.hook[hook] then
			self.hook[hook] = nil
		end
	end,
	disconnectAll = function(self)
		self.hook = {}
	end
})

--[[ hook ]
Inherits: instance

Description: Holds a callback function to be fired when hooked on an event object.

Properties:
	function func (read-only) - callback function.
	event event (read-only) - event object.

Functions:
	nil fire(...) - Fires the callback function.
	nil disconnect() - disconnects this hook from it's event.
]]
local hook = instance:class("hook",{
	func = nil,
	event = nil,
	fire = function(self,...)
		if self.func then
			self.func(...)
		end
	end,
	disconnect = function(self)
		if self.event then
			self.event:disconnect(self)
		end
	end
})