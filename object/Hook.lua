local Hook = Instance:class("Hook",3)({
	callback = nil,
	event = nil,
	fire = function(self,super,...)
		if self.callback then
			self.callback(...)
		end
	end,
	disconnect = function(self,super)
		if self.event then
			self.event:disconnect(self)
		end
	end
})