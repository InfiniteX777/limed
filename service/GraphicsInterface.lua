local insert,remove = table.insert,table.remove

local content = Instance:service"ContentService"
local game = Instance:service"GameInterface"
local input = Instance:service"UserInput"

local graphics = Instance:class("GraphicsInterface",2){
	color = Color:new(255,255,255),
	colors = {},
	scissor = nil,
	scissors = {},
	setColor = function(self,super,r,g,b,a)
		self.color:set(r,g,b,a)
		self.colors = {self.color}
		love.graphics.setColor(self.color:components())
	end,
	resetColor = function(self,super)
		self:setColor(255,255,255)
	end,
	pushColor = function(self,super,r,g,b,a)
		self.color = self.color*Color:new(r,g,b,a)
		insert(self.colors,self.color)
		love.graphics.setColor(self.color:components())
	end,
	popColor = function(self,super)
		if #self.colors > 1 then
			remove(self.colors)
			self.color = self.colors[#self.colors]
			love.graphics.setColor(self.color:components())
		end
	end,
	setScissor = function(self,super,...)
		self.scissors = {}
		self:pushScissor(...)
	end,
	pushScissor = function(self,super,...)
		self.scissor = {...}
		insert(self.scissors,self.scissor)
		love.graphics.setScissor(unpack(self.scissor))
	end,
	popScissor = function(self,super)
		if #self.scissors > 1 then
			remove(self.scissors)
			self.scissor = self.scissors[#self.scissors]
			love.graphics.setScissor(unpack(self.scissor))
		end
	end,
	newWindow = function(self,super,image)
		local image = content:loadImage(image)
		local w,h = image.width,image.height

		return Instance:new("Frame",function(self)
		self.fillColor.a = 0
			self.lineColor.a = 0
			self.image = image
			self.offset:set(0,0,w,h)
		end)
	end,
	newButton = function(self,super,image,tooltip,callback)
		local image = content:loadImage(image)
		local w,h = image.width/3,image.height
		local up = image:quad(0,0,w,h)
		local hover = image:quad(w,0,w,h)
		local down = image:quad(w*2,0,w,h)
		local hold = false
		local timer = nil

		local frame = Instance:new("Frame",function(self)
			self.fillColor.a = 0
			self.lineColor.a = 0
			self.image = up

			self.offset:set(0,0,w,h)

			self.mouseEntered:connect(function()
				self.image = hold and down or hover
				timer = 0
			end)

			self.mouseLeave:connect(function()
				self.image = up
				timer = nil
			end)

			self.mouseDown:connect(function(x,y,button)
				if button == 1 then
					timer = nil
					self.image = down
					hold = true
				end
			end)
		end)

		input.mouseUp:connect(function(x,y,button)
			if button == 1 and hold then
				hold = false

				if frame.hover then
					frame.image = hover

					if callback then
						callback()
					end
				else frame.image = up
				end
			end
		end)

		if tooltip then
			local txt = tooltip
			tooltip = Instance:new("Label",function(self)
				self.fillColor.a = 0
				self.lineColor.a = 0
				self.text:set(txt)
				self.textAlign = "bottomleft"
				self.active = false
				self.visible = false
				self:add(Instance:new("Label",function(self)
					self.fillColor.a = 0
					self.lineColor.a = 0
					self.text:set("#000000 "..txt)
					self.textAlign = "bottomleft"
					self.offset:set(2,2)
				end))
			end)

			frame:add(tooltip)

			game.gameUpdate:connect(function(dt)
				if timer then
					timer = timer+dt
				end
			end)

			game.gameDraw:connect(function()
				if timer and timer >= 1 then
					local p = Vector2:new(love.mouse.getPosition())-frame:absolutePosition()
					tooltip.offset:set(p.x,p.y)
					tooltip.visible = true
				else tooltip.visible = false
				end
			end)
		end

		return frame
	end,
	newLabelButton = function(self,super,image,text,callback)
		local frame = self:newButton(image,nil,callback)

		frame:add(Instance:new("Label",function(self)
			self.active = false
			self.fillColor.a = 0
			self.lineColor.a = 0
			self.textAlign = "middlecenter"
			self.scale:set(0,0,1,1)
			self:setText("#000000 "..text)
		end))

		return frame
	end
}
