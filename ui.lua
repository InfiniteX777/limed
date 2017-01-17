--[[ ui ]
Inherits: instance

Description: Contains the GUI elements.

Functions:
	(system-only) nil add( - Adds a new UI element. Only instances that inherits this class is allowed.
		ui v - Element.
	)
	(system-only) nil rem( - Removes the UI element.
		ui v - Element.
	)
	nil update( - Updates all of the UI elements.
		Number dt - Elapsed time.
	)
	nil draw(...) - Draws all of the UI elements.

Events:
	elementAdded( - Fired when a new element is added.
		ui v - Element.
	)
	elementRemoved( - Fired when an element belonging to this container has been removed.
					  Does not fire when a descendant (an element inside a container that is inside this container) is removed.
		ui v - Element.
	)
]]
local ui = instance:new("ui",3)({
	elements = {},
	add = function(self,v)
		self.elements[v] = true
		self.elementAdded:fire(v)
	end,
	rem = function(self,v)
		self.elements[v] = nil
		self.elementRemoved:fire(v)
	end,
	update = function(self,dt)
		for k,v in pairs(self.elements) do
			if v then
				k:update(dt)
			else self.elements[k] = nil
				self.elementRemoved:fire(v)
			end
		end
	end,
	draw = function(self,...)
		for k,v in pairs(self.elements) do
			if v then
				k:draw(...)
			else self.elements[k] = nil
				self.elementRemoved:fire(v)
			end
		end
	end,
	elementAdded = instance.event,
	elementRemoved = instance.event
})

local textLabel = instance:new("textLabel",3)({
	text = "textLabel",
	position = vec2:new(),
	rotation = 0,
	scale = vec2:new(),
	origin = vec2:new()
})