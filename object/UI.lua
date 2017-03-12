local min,floor,ceil = math.min,math.floor,math.ceil

local game = Instance:service"GameInterface"
local content = Instance:service"ContentService"
local graphics = Instance:service"GraphicsInterface"
local input = Instance:service"UserInput"

local UI = Instance:class("UI",3){
	parent = nil,
	selected = nil,
	layer = SkipList:new(),
	offset = Rect:new(),
	scale = Rect:new(),
	visible = true,
	active = true,
	wrap = false,
	hover = false,
	drag = false,
	draggable = false,
	new = function(self,super)
		input.mouseMoved:connect(function(x,y,dx,dy,...)
			local selected = self:getSelected()

			if self:isActive() then
				local layer = self:getLayer()
				local a,b = self:absolutePosition(),self:absoluteSize()

				if self.drag then
					self.offset:set(self.offset.x+dx,self.offset.y+dy)
				end

				if x >= a.x and x <= a.x+b.x and y >= a.y and y <= a.y+b.y and
				   (not selected or
				    selected == self or
					self:descendantOf(selected) or
					(layer and selected:getLayer() > layer)) then
					self:setSelected(self)

					if self.hover then
						self.mouseMoved:fire(x,y,dx,dy,...)
					else self.hover = true
						self.mouseEntered:fire(x,y,dx,dy,...)
					end

					return
				end
			end

			if self.hover then
				self.hover = false
				self.mouseLeave:fire(x,y,...)

				if selected == self then
					self:setSelected()
				end
			end
		end)
		input.mouseDown:connect(function(...)
			if self.hover and self:getSelected() == self then
				if self.draggable then
					self.drag = true
				end

				self.mouseDown:fire(...)
			end
		end)
		input.mouseUp:connect(function(...)
			self.drag = false

			if self.hover and self:getSelected() == self then
				self.mouseUp:fire(...)
			end
		end)
		input.mouseWheel:connect(function(...)
			if self.hover and self:getSelected() == self then
				self.mouseWheel:fire(...)
			end
		end)
	end,
	getSelected = function(self,super)
		return self.parent and self.parent:getSelected() or self.selected
	end,
	setSelected = function(self,super,ui)
		if self.parent then
			self.parent:setSelected(ui)
		else self.selected = ui
		end
	end,
	getLayer = function() return end,
	setLayer = function(self,super,layer)
		local parent = self.parent

		if not parent then return end
		-- Not in a group.

		local prev = self:getLayer()
		if prev then
			parent.layer:remove(prev,self)
		end

		parent.layer:insert(layer,self)

		self.getLayer = function()
			return layer
		end
	end,
	add = function(self,super,ui,layer,up,down,left,right)
		if ui:is("UI") then
			local layer = layer or 0

			ui.parent = self
			ui.up = up
			ui.down = down
			ui.left = left
			ui.right = right

			ui:setLayer(layer)
		end
	end,
	rem = function(self,super,ui)
		if ui:descendantOf(self) then
			self.layer:remove(ui:getLayer(),ui)

			ui.parent = nil
			ui.getLayer = nil
		end
	end,
	isActive = function(self,super)
		if not self.active then
			return self.active
		elseif self.parent then
			return self.parent:isActive()
		end

		return true
	end,
	isVisible = function(self,super)
		if not self.visible then
			return self.visible
		elseif self.parent then
			return self.parent:isVisible()
		end

		return true
	end,
	absoluteSize = function(self,super)
		if self.parent then
			return self.parent:absoluteSize()*self.scale.size+self.offset.size
		end

		return game.window*self.scale.size+self.offset.size
	end,
	absolutePosition = function(self,super)
		if self.parent then
			return self.parent:absolutePosition()+self.parent:absoluteSize()*self.scale.position+self.offset.position
		end

		return game.window*self.scale.position+self.offset.position
	end,
	absoluteRotation = function(self,super)
		if self.parent then
			return self.parent:absoluteRotation()+self.offset.rotation-self.scale.rotation
		end

		return self.offset.rotation-self.scale.rotation
	end,
	rect = function(self,super)
		local position = self:absolutePosition()
		local size = self:absoluteSize()
		local rotation = self:absoluteRotation()

		return Rect:new(
			position.x,
			position.y,
			size.x,
			size.y,
			rotation
		)
	end,
	descendantOf = function(self,super,ui)
		return self.parent and (self.parent == ui or self.parent:descendantOf(ui))
	end,
	ancestorOf = function(self,super,ui)
		return ui.parent and (ui.parent == self or self:ancestorOf(ui.parent))
	end,
	update = function(self,super,dt)
		for k,v in self.layer:ipairs() do
			v:update(dt)
		end
	end,
	draw = function(self,super,...)
		if not self.visible then return end

		local rect = self:rect()
		local d = rect.rotation == 0 and self.wrap

		if d then
			graphics:pushScissor(rect.x,rect.y,rect.w,rect.h)
		end

		for k,v in self.layer:ipairs() do
			v:draw(...)
		end

		if d then
			graphics:popScissor()
		end
	end,
	destroy = function(self,super)
		local selected = self:getSelected()
		if selected and (selected == self or selected:descendantOf(self)) then
			self:setSelected()
		end

		if self.parent then
			self.parent:rem(self)
		end

		for _,v in self.layer:ipairs() do
			self:rem(v)
			v:destroy()
		end

		super.destroy(self)
	end,
	mouseEntered = Instance:event(),
	mouseMoved = Instance:event(),
	mouseLeave = Instance:event(),
	mouseDown = Instance:event(),
	mouseUp = Instance:event(),
	mouseWheel = Instance:event()
}

local Frame = UI:class("Frame",3){
	fillColor = Color:new(255,255,255),
	lineColor = Color:new(),
	image = nil,
	new = function(self,super)
		super.constructor(self)

		self.canvas = love.graphics.newCanvas(100,100)
	end,
	update = function(self,super,dt)
		if self.image then
			self.image:update(dt)
		end

		super.update(self,dt)
	end,
	draw = function(self,super,x,y,angle,sx,sy,...)
		if not self.visible then return end

		local angle,sx,sy = angle or 0,sx or 1,sy or 1
		local rect = self:rect()
		local rot = angle+rect.rotation
		local a,b = rect.position:rotate(-rect.size/2,-rot),rect.size
		local image = self.image

		love.graphics.push()
		love.graphics.translate(x,y)
		love.graphics.scale(sx,sy)
		love.graphics.rotate(rot)

		if self.fillColor.a > 0 then
			game:pushColor(self.fillColor:components())

			love.graphics.rectangle("fill",a.x,a.y,b.x,b.y)

			game:popColor()
		end

		if self.lineColor.a > 0 then
			game:pushColor(self.lineColor:components())

			love.graphics.rectangle("line",a.x,a.y,b.x,b.y)

			game:popColor()
		end

		if image then
			image:draw(
				a.x,
				a.y,
				0,
				b.x/image.width,
				b.y/image.height
			)
		end

		love.graphics.pop()

		super.draw(self,x,y,angle,sx,sy,...)
	end
}

local BorderedFrame = Frame:class("BorderedFrame",3){
	borderImage = nil,
	borderAtlas = nil,
	borderRect = nil,
	borderEdgeSize = 8,
	borderEdgeStyle = "stretch",
	borderBodyStyle = "stretch",
	borderColor = Color:new(255,255,255),
	update = function(self,super,dt)
		super.update(self,dt)

		local image = self.borderImage

		if image then
			if not self.borderAtlas then
				self.borderAtlas = love.graphics.newSpriteBatch(image.image)
			end

			local atlas = self.borderAtlas
			if atlas:getTexture() ~= image.image then
				atlas:setTexture(image.image)
			end

			local rect = self:rect()
			local b = rect.size
			local size = self.borderEdgeSize
			if not self.borderRect or self.borderRect.size ~= rect.size then
				self.borderRect = rect
				atlas:clear()

				-- Corners (Topleft, Topright, Bottomleft, Bottomright)
				atlas:add(
					image:get(0,0,size,size),
					0,0
				)
				atlas:add(
					image:get(image.width-size,0,size,size),
					b.x-size,0
				)
				atlas:add(
					image:get(0,image.height-size,size,size),
					0,b.y-size
				)
				atlas:add(
					image:get(image.width-size,image.height-size,size,size),
					b.x-size,b.y-size
				)

				-- Edges (Top, Bottom, Left, Right)
				local edge = Vector2:new(image.height,image.width)-size*2
				if self.borderEdgeStyle == "stretch" then
					atlas:add(
						image:get(size,0,edge.x,size),
						size,0,0,(b.x-size*2)/edge.x,1
					)
					atlas:add(
						image:get(size,image.height-size,edge.x,size),
						size,b.y-size,0,(b.x-size*2)/edge.x,1
					)
					atlas:add(
						image:get(0,size,size,edge.y),
						0,size,0,1,(b.y-size*2)/edge.y
					)
					atlas:add(
						image:get(image.width-size,size,size,edge.y),
						b.x-size,size,0,1,(b.y-size*2)/edge.y
					)
				elseif self.borderEdgeStyle == "tile" then
					local len = b-size*2
					for i=0,ceil(len.x/edge.x)-1 do
						local width = min(edge.x,len.x)

						atlas:add(
							image:get(size,0,width,size),
							size+i*edge.x,0,0,1,1
						)
						atlas:add(
							image:get(size,image.height-size,width,size),
							size+i*edge.x,b.y-size,0,1,1
						)

						len.x = len.x-edge.x
					end

					for i=0,ceil(len.y/edge.y)-1 do
						local height = min(edge.y,len.y)

						atlas:add(
							image:get(0,size,size,height),
							0,size+i*edge.y,0,1,1
						)
						atlas:add(
							image:get(image.width-size,size,size,height),
							b.x-size,size+i*edge.y,0,1,1
						)

						len.y = len.y-edge.y
					end
				end

				-- Center
				if self.borderBodyStyle == "stretch" then
					atlas:add(
						image:get(size,size,edge.x,edge.y),
						size,
						size,
						0,
						(b.x-size*2)/(image.width-size*2),
						(b.y-size*2)/(image.height-size*2)
					)
				elseif self.borderBodyStyle == "tile" then
					local len = b-size*2
					local mx,my = ceil(len.x/edge.x)-1,ceil(len.y/edge.y)-1

					for y=0,my do
						for x=0,mx do
							atlas:add(
								image:get(
									size,
									size,
									min(edge.x,len.x-x*edge.x),
									min(edge.y,len.y-y*edge.y)
								),
								size+x*edge.x,
								size+y*edge.y,
								0,
								1,
								1
							)
						end
					end
				end

				atlas:flush()
			end
		end
	end,
	draw = function(self,super,x,y,angle,sx,sy,...)
		if not self.visible then return end

		local angle,sx,sy = angle or 0,sx or 1,sy or 1
		local image = self.borderImage
		local rect = self:rect()
		local rot = angle+rect.rotation
		local a,b = rect.position:rotate(-rect.size/2,-rot),rect.size
		local size = image and self.borderEdgeSize or 0

		local atlas = self.borderAtlas
		if atlas then
			love.graphics.push()
			love.graphics.scale(sx,sy)
			love.graphics.rotate(rot)
			love.graphics.translate(x+a.x,y+a.y)

			love.graphics.draw(atlas)

			love.graphics.pop()
		end

		super.draw(
			self,
			x,
			y,
			angle,
			sx,
			sy,
			...
		)
	end
}

local Label = Frame:class("Label",3){
	text = ColoredText:new(),
	textSpeed = 0,
	textIndex = 0,
	textAlign = "topleft",
	textWrap = false,
	font = nil,
	new = function(self,super)
		super.constructor(self)

		self.font = content:loadFont()
	end,
	setText = function(self,super,text,speed)
		self.text:set(text)
		self.textSpeed = speed
		self.textIndex = 0
	end,
	update = function(self,super,dt)
		if self.textSpeed > 0 then
			self.textIndex = min(self.textIndex+self.textSpeed*dt,self.text.abs:len())
		end

		super.update(self,dt)
	end,
	draw = function(self,super,x,y,angle,sx,sy,...)
		if not self.visible then return end

		local angle,sx,sy = angle or 0,sx or 1,sy or 1

		super.draw(self,x,y,angle,sx,sy,...)

		local rect = self:rect()
		local rot = angle+rect.rotation

		self.font.text = self.textSpeed > 0 and self.text:cut(1,floor(self.textIndex)) or self.text
		self.font.align = self.textAlign
		self.font.wrap = self.textWrap and rect.size.x or nil

		local ox,oy = unpack(content.fontAlignment[self.textAlign])
		local pos = (rect.position+rect.size*Vector2:new(self.textWrap and 0 or ox,oy)):rotate(rect.center,rot)
		self.font:draw(x+pos.x*sx,y+pos.y*sy,rot,sx,sy,...)
	end
}
