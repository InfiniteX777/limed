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
	offset = Rect:new(),
	scale = Rect:new(),
	fillColor = Color:new(255,255,255),
	outlineColor = Color:new(),
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

		love.graphics.rotate(rot)
		love.graphics.setColor(self.fillColor:components())
		love.graphics.rectangle("fill",a.x,a.y,b.x*sx,b.y*sy)
		love.graphics.setColor(self.outlineColor:components())
		love.graphics.rectangle("line",a.x,a.y,b.x*sx,b.y*sy)
		if self.image then
			local width,height = self.image.width,self.image.height
			width = b.x/width
			height = b.y/height
			self.image:draw(a.x,a.y,0,width*sx,height*sy)
		end
		love.graphics.origin()
	end,
	mouseEntered = Instance.event,
	mouseMoved = Instance.event,
	mouseLeave = Instance.event,
	mouseDown = Instance.event,
	mouseUp = Instance.event,
	mouseWheel = Instance.event
})

local alignment = {
	topleft = function(pos,size)
		return pos
	end,
	middleleft = function(pos,size)
		return Vector2:new(pos.x,pos.y+size.y/2)
	end,
	bottomleft = function(pos,size)
		return Vector2:new(pos.x,pos.y+size.y)
	end,
	topcenter = function(pos,size)
		return Vector2:new(pos.x+size.x/2,pos.y)
	end,
	middlecenter = function(pos,size)
		return pos+size/2
	end,
	bottomcenter = function(pos,size)
		return Vector2:new(pos.x+size.x/2,pos.y+size.y)
	end,
	topright = function(pos,size)
		return Vector2:new(pos.x+size.x,pos.y)
	end,
	middleright = function(pos,size)
		return Vector2:new(pos.x+size.x,pos.y+size.y/2)
	end,
	bottomright = function(pos,size)
		return pos+size
	end
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
		local pos = alignment[self.textAlign](rect.position,rect.size*Vector2:new(1,sy)):rotateToVectorSpace(rect.center,rot)
		self.font:draw(x+pos.x,y+pos.y,rot,sx,sy,...)
	end
})