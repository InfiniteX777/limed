--[[ UI ]
Inherits: Instance

Description: Contains the GUI elements.

Functions:
	(system-only) nil add( - Adds a new UI element. Only instances that inherits this class is allowed.
		UI v - Element.
	)
	(system-only) nil rem( - Removes the UI element.
		UI v - Element.
	)
	nil update( - Updates all of the UI elements.
		Number dt - Elapsed time.
	)
	nil draw(...) - Draws all of the UI elements.

Events:
	elementAdded( - Fired when a new element is added.
		UI v - Element.
	)
	elementRemoved( - Fired when an element belonging to this container has been removed.
					  Does not fire when a descendant (an element inside a container that is inside this container) is removed.
		UI v - Element.
	)
]]
local UI = Instance:class("UI",3)({
	elements = {},
	add = function(self,v)
		if v:is("UI") then
			self.elements[v] = true
			self.elementAdded:fire(v)
		end
	end,
	rem = function(self,v)
		if self.elements[v] then
			self.elements[v] = nil
			self.elementRemoved:fire(v)
		end
	end,
	destroy = function(self)
		for k,v in pairs(self.elements) do
			if v then
				k:destroy()
			else self.elements[k] = nil
				self.elementRemoved:fire(v)
			end
		end
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
	elementAdded = Instance.event,
	elementRemoved = Instance.event
})

local Frame = UI:class("Frame",3)({
	position = {
		offset = Vector2:new(),
		scale = Vector2:new()
	},
	rotation = 0,
	size = {
		offset = Vector2:new(),
		scale = Vector2:new()
	},
	origin = Vector2:new(),
	fillColor = Color:new(255,255,255),
	outlineColor = Color:new(),
	image = nil,
	hover = false,
	new = function(self)
		local InputService = Instance:service("InputService")
		self.mouseMovedHook = InputService.mouseMoved:connect(function(x,y,...)
			local a,b = self:rect()
			if (a-b).mag > 0 then
				if x >= a.x and x <= b.x and y >= a.y and y <= b.y then
					if not self.hover then
						self.hover = true
						self.mouseEntered:fire(x,y,...)
					else self.mouseMoved:fire(x,y,...)
					end
				elseif self.hover then
					self.hover = false
					self.mouseLeave:fire(x,y,...)
				end
			end
		end)
		self.mouseDownHook = InputService.mouseDown:connect(function(...)
			if self.hover then
				self.mouseDown:fire(...)
			end
		end)
		self.mouseUpHook = InputService.mouseUp:connect(function(...)
			if self.hover then
				self.mouseUp:fire(...)
			end
		end)
		self.mouseWheelHook = InputService.mouseWheel:connect(function(...)
			if self.hover then
				self.mouseWheel:fire(...)
			end
		end)
	end,
	rect = function(self)
		local screen = Vector2:new(love.graphics.getDimensions())
		local position = self.position.offset+self.position.scale*screen
		local size = self.size.offset+self.size.scale*screen
		return position:rect(size+position)
	end,
	destroy = function(self)
		for _,v in pairs({"Moved","Down","Up","Wheel"}) do
			if self["mouse"..v.."Hook"] then
				self["mouse"..v.."Hook"]:disconnect()
			end
		end
	end,
	draw = function(self,x,y,angle,sx,sy)
		local a,b = self:rect()
		b = b-a
		love.graphics.setColor(self.fillColor:components())
		love.graphics.rectangle("fill",a.x,a.y,b.x,b.y)
		love.graphics.setColor(self.outlineColor:components())
		love.graphics.rectangle("line",a.x,a.y,b.x,b.y)
	end,
	mouseEntered = Instance.event,
	mouseMoved = Instance.event,
	mouseLeave = Instance.event,
	mouseDown = Instance.event,
	mouseUp = Instance.event,
	mouseWheel = Instance.event
})

local Label = Frame:class("Label",3)({
	text = "Label",
	textAlign = "center",
	textColor = Color:new(),
	textWrap = false,
	draw = function(self,x,y,angle,sx,sy)
		local a,b = self:rect()
		local pos = a:lerp(b,0.5)
		local size = b-a
		local font = love.graphics.getFont()
		love.graphics.setColor(self.textColor:components())

		if self.textAlign == "left" then
			pos = Vector2:new(a.x,(b-y+a.y)/2)
		elseif self.textAlign == "center" then
			pos = pos-Vector2:new(love.graphics.getDimension()/2,0)
		else pos = 
		end

		if self.textWrap then
			local txt,wrap = font:getWrap(self.text,b.x)
		else local txt = font:getWidth(self.text)
			love.graphics.printf(self.text,0,a.y,math.huge,self.textAlign)
		end
		--love.graphics.print(self.text,a.x,a.y)
		love.graphics.printf(self.text,0,a.y,size.x,self.textAlign)
	end
})

local Button = Label:class("Button",3)({
})