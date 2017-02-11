local floor,max,min = math.floor,math.max,math.min

local cache = {}

local Image = Instance:class("Image",4)({
	image = nil,
	color = Color:new(255,255,255),
	width = 0,
	height = 0,
	flip = false,
	bake = function(self,w,h)
		local fx,fy = floor(self.width/w),floor(self.height/h)
		for x=0,fx-1 do
			for y=0,fy-1 do
				local t = lemon.table.init(cache,self.image,w,h,x)
				if not t[y] then
					t[y] = love.graphics.newQuad(x*w,y*h,w,h,self.width,self.height)
				end
			end
		end
	end,
	quad = function(self,w,h,x,y)
		return self:new("Quad",function(t)
			t.width = w
			t.height = h
			t.x = x or 0
			t.y = y or 0
			t.fx = floor(self.width/w)
			t.fy = floor(self.height/h)
		end)
	end,
	sprite = function(self,w,h,x,y)
		return self:new("Sprite",function(t)
			t.width = w
			t.height = h
			t.x = x or 0
			t.y = y or 0
			t.fx = floor(self.width/w)
			t.fy = floor(self.height/h)
			t.endFrame = t.fx
		end)
	end,
	draw = function(self,x,y,angle,sx,sy,...)
		if self.image then
			love.graphics.push()
			love.graphics.setColor(self.color:components())
			local pos,size = Vector2:new(x,y),Vector2:new(self.width*sx,self.height*sy)
			if self.flip then
				sx = -sx
				pos.x = pos.x+size.x
			end
			pos = pos:rotateToVectorSpace(pos+size/2,angle)
			love.graphics.draw(self.image,pos.x,pos.y,angle,sx,sy,...)
			love.graphics.pop()
		end
	end
})

local Quad = Image:class("Quad",4)({
	frame = nil,
	fx = 0,
	fy = 0,
	x = 0,
	y = 0,
	draw = function(self,x,y,angle,sx,sy,...)
		if self.image and self.x < self.fx and self.y < self.fy then
			if not self.frame then
				local t = lemon.table.init(cache,self.image,self.width,self.height,self.x)
				if not t[self.y] then
					t[self.y] = love.graphics.newQuad(
						self.x*self.width,
						self.y*self.height,
						self.width,
						self.height,
						self.image:getWidth(),
						self.image:getHeight()
					)
				end
				self.frame = t[self.y]
			end
			love.graphics.push()
			love.graphics.setColor(self.color:components())
			local pos,size = Vector2:new(x,y),Vector2:new(self.width*sx,self.height*sy)
			if self.flip then
				sx = -sx
				pos.x = pos.x+size.x
			end
			pos = pos:rotateToVectorSpace(pos+size/2,angle)
			love.graphics.draw(self.image,self.frame,pos.x,pos.y,angle,sx,sy,...)
			love.graphics.pop()
		end
	end,
	__draw = true
})

local Sprite = Quad:class("Sprite",4)({
	delay = 1/12,
	timer = 0,
	speed = 1,
	startFrame = 0,
	endFrame = 0,
	direction = 1,
	loop = true,
	playing = false,
	bounce = false,
	play = function(self)
		self.playing = true
		self.animationStarted:fire()
	end,
	pause = function(self)
		self.playing = false
		self.animationStopped:fire()
	end,
	stop = function(self)
		self.playing = false
		self.x = self.startFrame
		self.animationStopped:fire()
	end,
	seek = function(self,x,y)
		self.x = max(self.startFrame,min(x or self.x,self.endFrame))
		self.y = y or self.y
	end,
	update = function(self,dt)
		self.startFrame = max(0,min(self.startFrame,self.fx-1))
		self.endFrame = max(self.startFrame,min(self.endFrame,self.fx-1))
		if self.playing and self.delay > 0 then
			self.timer = self.timer+dt*self.speed
			if self.timer >= self.delay then
				self.timer = self.timer-self.delay
				self.x = self.x+self.direction
				if self.direction == 1 and self.x >= self.endFrame or self.direction == -1 and self.x <= self.startFrame then
					if self.bounce then
						self.direction = self.direction*-1
					end
					if self.direction == 1 then
						self.playing = self.loop
						self.x = self.playing and self.startFrame or self.endFrame
						if not self.playing then
							self.animationEnded:fire()
						end
					else self.x = self.endFrame
					end
				end
			end
		end
		self.frame = nil
	end,
	animationStarted = Instance.event,
	animationEnded = Instance.event,
	animationStopped = Instance.event
})