local floor,ceil,max,min = math.floor,math.ceil,math.max,math.min

local cache = {}

local function get(image,x,y,w,h)
	local k = x.."/"..y.."/"..w.."/"..h

	if not cache[image] or not cache[image][k] then
		lemon.table.init(cache,image)[k] = love.graphics.newQuad(x,y,w,h,image:getDimensions())
	end

	return cache[image][k]
end

local Image = Instance:class("Image",4)({
	image = nil,
	color = Color:new(255,255,255),
	width = 0,
	height = 0,
	flip = false,
	bake = function(self,super,w,h,mx,my,sx,sy)
		local mx,my,sx,sy = mx or 0,my or 0,sx or 0,sy or 0
		for y=0,ceil(((self.height-my)/(h+sy)))-1 do
			for x=0,ceil(((self.width-mx)/(w+sx)))-1 do
				get(
					self.image,
					mx+x*(w+sx),
					my+y*(h+sy),
					w,h
				)
			end
		end
	end,
	quad = function(self,super,x,y,w,h)
		local x,y = x or 0,y or 0
		return self:new("Quad",function(t)
			t.width = w
			t.height = h
			t.x = x
			t.y = y
		end)
	end,
	sprite = function(self,super,w,h,fx,fy,mx,my,sx,sy)
		local fx,fy,mx,my,sx,sy = fx or 0,fy or 0,mx or 0,my or 0,sx or 0,sy or 0
		return self:new("Sprite",function(t)
			t.width = w
			t.height = h
			t.x = mx+fx*(w+sx)
			t.y = mx+fx*(h+sy)
			t.fx = fx
			t.fy = fy
			t.mx = mx
			t.my = my
			t.sx = sx
			t.sy = sy
			t.mfx = ceil(((self.width-mx)/(w+sx)))
			t.mfy = ceil(((self.height-my)/(h+sy)))
			t.endFrame = t.mfx
		end)
	end,
	draw = function(self,super,x,y,angle,sx,sy,...)
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
	x = 0,
	y = 0,
	get = function(self,super)
		if self.image then
			return get(self.image,self.x,self.y,self.width,self.height)
		end
	end,
	draw = function(self,super,x,y,angle,sx,sy,...)
		if self.image then
			if not self.frame then
				self.frame = self:get()
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
	end
})

local Sprite = Quad:class("Sprite",4)({
	fx = 0,
	fy = 0,
	mfx = 0,
	mfy = 0,
	mx = 0,
	my = 0,
	sx = 0,
	sy = 0,
	delay = 1/12,
	timer = 0,
	speed = 1,
	startFrame = 0,
	endFrame = 0,
	direction = 1,
	loop = true,
	playing = false,
	bounce = false,
	sheet = {},
	play = function(self,super)
		self.playing = true
		self.animationStarted:fire()
	end,
	pause = function(self,super)
		self.playing = false
		self.animationStopped:fire()
	end,
	stop = function(self,super)
		self.playing = false
		self.fx = self.startFrame
		self.timer = 0
		self.animationStopped:fire()
	end,
	seek = function(self,super,x,y)
		self.fx = max(self.startFrame,min(x or self.fx,self.endFrame))
		self.fy = y or self.fy
	end,
	update = function(self,super,dt)
		local delay = self.delay
		if #self.sheet > 0 then
			self.startFrame = 0
			self.endFrame = #self.sheet
			delay = self.sheet[self.fx+1].delay
		else self.startFrame = max(0,min(self.startFrame,self.mfx-1))
			self.endFrame = max(self.startFrame,min(self.endFrame,self.mfx-1))
		end
		if self.playing and delay > 0 then
			self.timer = self.timer+dt*self.speed
			if self.timer >= delay then
				self.timer = self.timer-delay
				self.fx = self.fx+self.direction
				if self.direction == 1 and self.fx >= self.endFrame or self.direction == -1 and self.fx <= self.startFrame then
					if self.bounce then
						self.direction = self.direction*-1
					end
					if self.direction == 1 then
						self.playing = self.loop
						self.fx = self.playing and self.startFrame or self.endFrame
						if not self.playing then
							self.animationEnded:fire()
						end
					else self.fx = self.endFrame
					end
				end
			end
		end
		self.frame = nil
		if #self.sheet > 0 then
			self.x = self.sheet[self.fx+1].x
			self.y = self.sheet[self.fx+1].y
		else self.x = self.mx+self.fx*(self.width+self.sx)
			self.y = self.my+self.fy*(self.height+self.sy)
		end
	end,
	animationStarted = Instance:event(),
	animationEnded = Instance:event(),
	animationStopped = Instance:event()
})