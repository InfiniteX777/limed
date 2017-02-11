local UI = Instance:class("UI",3)({
	elements = {},
	visible = true,
	active = true,
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
		if self.active then
			for k,v in pairs(self.elements) do
				if v then
					k:update(dt)
				else self.elements[k] = nil
					self.elementRemoved:fire(v)
				end
			end
		end
	end,
	draw = function(self,...)
		if self.visible then
			for k,v in pairs(self.elements) do
				if v then
					k:draw(...)
				else self.elements[k] = nil
					self.elementRemoved:fire(v)
				end
			end
		end
	end,
	elementAdded = Instance.event,
	elementRemoved = Instance.event
})

local Frame = UI:class("Frame",3)({
	offset = Rect:new(),
	scale = Rect:new(),
	fillColor = Color:new(255,255,255),
	lineColor = Color:new(),
	image = nil,
	hover = false,
	new = function(self)
		local InputService = Instance:service("InputService")
		self.mouseMovedHook = InputService.mouseMoved:connect(function(x,y,...)
			local rect = self:rect()
			if rect.area > 0 then
				if x >= rect.position.x and x <= rect.position.x+rect.size.x and y >= rect.position.y and y <= rect.position.y+rect.size.y then
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
		return Rect:new(
			self.offset.position+self.scale.position*screen,
			self.offset.size+self.scale.size*screen,
			self.offset.rotation-self.scale.rotation
		)
	end,
	destroy = function(self)
		for _,v in pairs({"Moved","Down","Up","Wheel"}) do
			if self["mouse"..v.."Hook"] then
				self["mouse"..v.."Hook"]:disconnect()
			end
		end
	end,
	draw = function(self,x,y,angle,sx,sy)
		local rect = self:rect()
		local rot = angle+rect.rotation
		rect.position = rect.center+Vector2:new(x,y)
		rect.position = rect.position:rotateToVectorSpace(Vector2:new(),-rot)
		rect.position = rect.position-rect.size/2
		local a,b = rect.position,rect.size

		love.graphics.push()
		love.graphics.rotate(rot)
		if self.fillColor.a > 0 then
			love.graphics.setColor(self.fillColor:components())
			love.graphics.rectangle("fill",a.x,a.y,b.x*sx,b.y*sy)
		end
		if self.lineColor.a > 0 then
			love.graphics.setColor(self.lineColor:components())
			love.graphics.rectangle("line",a.x,a.y,b.x*sx,b.y*sy)
		end
		if self.image then
			b = b/Vector2:new(self.image.width,self.image.height)
			self.image:draw(a.x,a.y,0,b.x*sx,b.y*sy)
		end
		love.graphics.pop()
	end,
	mouseEntered = Instance.event,
	mouseMoved = Instance.event,
	mouseLeave = Instance.event,
	mouseDown = Instance.event,
	mouseUp = Instance.event,
	mouseWheel = Instance.event
})

local alignment = {
	topleft = {0,0},
	middleleft = {0,0.5},
	bottomleft = {0,1},
	topcenter = {0.5,0},
	middlecenter = {0.5,0.5},
	bottomcenter = {0.5,1},
	topright = {1,0},
	middleright = {1,0.5},
	bottomright = {1,1}
}

local Label = Frame:class("Label",3)({
	text = "",
	textAlign = "middlecenter",
	textColor = Color:new(),
	textWrap = false,
	font = nil,
	new = function(self)
		self.font = Instance:service("ContentService"):getFont()
	end,
	draw = function(self,x,y,angle,sx,sy,...)
		local rect = self:rect()
		local rot = angle+rect.rotation
		self.font.text = self.text
		self.font.color = self.textColor ~= self.font.color and self.textColor:clone() or self.font.color
		self.font.align = self.textAlign
		self.font.wrap = self.textWrap and rect.size.x or nil
		local offset = Vector2:new(unpack(alignment[self.textAlign]))
		local pos = (rect.position+rect.size*offset*Vector2:new(sx,sy)):rotateToVectorSpace(rect.center,rot)
		self.font:draw(x+pos.x,y+pos.y,rot,sx,sy,...)
	end
})