--[[ Hook ]
Inherits: Instance

Description: Holds a callback function to be fired when hooked on an event object.

Properties:
	function func (read-only) - callback function.
	event event (read-only) - event object.

Functions:
	nil fire(...) - Fires the callback function.
	nil disconnect() - disconnects this hook from its event.
]]
local Hook = Instance:class("Hook",3)({
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