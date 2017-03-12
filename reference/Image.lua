local floor,ceil,max,min = math.floor,math.ceil,math.max,math.min
local graphics = Instance:service"GraphicsInterface"

local cache = {}

local Image = Instance:class("Image",4){
	image = nil,
	color = Color:new(255,255,255),
	width = 0,
	height = 0,
	flip = false,
	bake = function(self,super,w,h,mx,my,sx,sy)
		local mx,my,sx,sy = mx or 0,my or 0,sx or 0,sy or 0
		for y=0,ceil(((self.height-my)/(h+sy)))-1 do
			for x=0,ceil(((self.width-mx)/(w+sx)))-1 do
				self:get(
					mx+x*(w+sx),
					my+y*(h+sy),
					w,h
				)
			end
		end
	end,
	get = function(self,super,x,y,w,h)
		local x,y,w,h = x or 0,y or 0,w or self.width,h or self.height
		local image = self.image
		local k = x.."/"..y.."/"..w.."/"..h

		if not cache[image] or not cache[image][k] then
			lemon.table.init(cache,image)[k] = love.graphics.newQuad(x,y,w,h,image:getDimensions())
		end

		return cache[image][k]
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
			local angle,sx,sy = angle or 0,sx or 1,sy or 1
			love.graphics.push()
			graphics:pushColor(self.color:components())

			local pos = Vector2:new(x,y)
			local size = Vector2:new(self.width*sx,self.height*sy)
			if self.flip then
				sx = -sx
				pos.x = pos.x+size.x
			end
			pos = pos:rotate(pos+size/2,angle)
			love.graphics.draw(self.image,pos.x,pos.y,angle,sx,sy,...)

			graphics:popColor()
			love.graphics.pop()
		end
	end
}

local Quad = Image:class("Quad",4){
	frame = nil,
	x = 0,
	y = 0,
	draw = function(self,super,x,y,angle,sx,sy,...)
		local angle,sx,sy = angle or 0,sx or 1,sy or 1
		if self.image then
			local angle,sx,sy = angle or 0,sx or 1,sy or 1

			love.graphics.push()
			graphics:pushColor(self.color:components())

			self.frame = self.frame or self:get(self.x,self.y,self.width,self.height)

			local pos,size = Vector2:new(x,y),Vector2:new(self.width*sx,self.height*sy)

			if self.flip then
				sx = -sx
				pos.x = pos.x+size.x
			end

			pos = pos:rotate(pos+size/2,angle)
			love.graphics.draw(self.image,self.frame,pos.x,pos.y,angle,sx,sy,...)

			graphics:popColor()
			love.graphics.pop()
		end
	end
}

local Sprite = Quad:class("Sprite",4){
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
	end,
	pause = function(self,super)
		self.playing = false
	end,
	stop = function(self,super)
		self.playing = false
		self.fx = self.startFrame
		self.timer = 0
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
	end
}
