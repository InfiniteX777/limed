local cache = {}

--[[ bitmap ]
Inherits: instance

Description: Creates a bitmap sheet. All bitmaps are stored and recycled.
			 Starting frame is [0,0].

Properties:
	Image image (read-only) - image source.
	Integer fx (read-only) - number of frames from left to right.
	Integer fy (read-only) - number of frames from top to bottom.
	Table+nil sheet (read-only) - A list of frames of the bitmap. Needs to use 'bake' function first or it will return nil.

Functions:
	nil bake( - Creates a frame sheet.
		String source - image path.
		Integer w - width pixels per frame.
		Integer h - height pixels per frame.
	)
	nil dump() - Clears the bitmap's global frame sheet cache. Does not remove any existing frame sheets.
	frame get( - Gets a frame from the bitmap's frame sheet.
		Integer x - frame x.
		Integer y - frame y.
	) - the frame.
]]
local bitmap = instance:class("bitmap",3)({
	fx = 0,
	fy = 0,
	w = 0,
	h = 0,
	bake = function(self,source,w,h)
		if cache[w] and cache[w][h] and cache[w][h][source] then
			self.image = cache[w][h][source].image
			self.sheet = cache[w][h][source].sheet
		else cache[w] = cache[w] or {}
			cache[w][h] = cache[w][h] or {}
			cache[w][h][source] = {}
			self.image = love.graphics.newImage(source)
			self.image:setFilter("nearest","nearest")
			local imgw = self.image:getWidth()
			local imgh = self.image:getHeight()
			self.w = w or imgw
			self.h = h or imgh
			self.fx = math.floor(imgw/self.w)
			self.fy = math.floor(imgh/self.h)
			self.sheet = {}
			for x=0,self.fx-1 do
				for y=0,self.fy-1 do
					self.sheet[x+y*self.fx] = love.graphics.newQuad(x*self.w,y*self.h,self.w,self.h,imgw,imgh)
				end
			end
			cache[w][h][source].image = self.image
			cache[w][h][source].sheet = self.sheet
		end
	end,
	dump = function(self)
		cache = {}
	end,
	get = function(self,x,y)
		x = x or 0
		y = y or 0
		if not self.image or not self.sheet[x+y*self.fx] then return end
		local v = instance:new("frame")
		v.frame = self.sheet[x+y*self.fx]
		v.bitmap = self

		return v
	end
})

--[[ frame ]
Inherits: instance

Description: A frame from a bitmap.

Properties:
	Quad frame (read-only) - A cropped out image.
	bitmap bitmap - A bitmap source.

Functions:
	nil draw( - Draws the current frame.
		Integer x - Pixel from left to right.
		Integer y - Pixel from top to bottom.
		Number angle - image rotation.
		Number sx - scale x.
		Number sy - scale y.
	)
]]
local frame = instance:class("frame",3)({
	frame = nil,
	bitmap = nil,
	bob = "HI",
	draw = function(self,x,y,angle,sx,sy)
		if self.frame then
			love.graphics.draw(self.bitmap.image,self.frame,x,y,angle,sx,sy)
		end
	end
})

--[[ sprite ]
Inherits: frame

Description: An animation composed of frame objects.

Properties:
	Number delay - seconds between frames.
	Number timer (read-only) - time until next frame.
	Number speed - how fast the animation is.
	Integer x (read-only) - current frame from left to right.
	Integer y (read-only) - current frame from top to bottom.
	Integer startFrame - Starting frame from left to right. Cannot be below 0 or higher than the maximum frames of the current bitmap.
	Integer endFrame - Ending frame from left to right. Cannot be below 'startFrame' or higher than the maximum frames of the current bitmap.
	Integer direction (read-only) - The running direction (1 = right, -1 = left)
	Boolean loop - If the animation is looped. The animation will automatically stop when the animation ends and this is set to 'false'.
	Boolean playing (read-only) - If the animation is playing.
	Boolean bounce - If set to 'true', the animation will switch 'directions' when reaching the 'endFrame', and vice-versa.

Functions:
	nil play() - Plays the animation.
	nil plause() - Stops the animation.
	nil stop() - Stops the animation and sets the current frame to 'startFrame'.
	nil seek( - moves the current frame to the desired frame.
		Integer+nil x - frame from left to right. Will not be changed if nil.
		Integer+nil y - frame from top to bottom. Will not be changed if nil.
	)
	nil update( - Updates the current state of the animation.
		Number dt - elapsed time.
	)

Events:
	animationStarted() - Fired when the playing the animation.
	animationEnded() - Fired when the animation has ended. Does not work if 'loop' is true.
	animationStopped() - Fired when the animation is forcibly stopped (using :pause() or :stop()).
]]
local sprite = frame:class("sprite",3)({
	delay = 1/12,
	timer = 0,
	speed = 1,
	x = 0,
	y = 0,
	startFrame = 0,
	endFrame = -1,
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
		self.x = math.max(self.startFrame,math.min(x or self.x,self.endFrame))
		self.y = y or self.y
	end,
	update = function(self,dt)
		self.startFrame = math.max(0,math.min(self.startFrame,self.bitmap.fx-1))
		self.endFrame = self.endFrame == -1 and self.bitmap.fx-1 or math.max(self.startFrame,math.min(self.endFrame,self.bitmap.fx-1))
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
						self.x = self.bounce and self.startFrame or self.endFrame
						if not self.playing then
							self.animationEnded:fire()
						end
					else self.x = self.endFrame
					end
				end
			end
		end
		self.frame = self.bitmap.sheet[self.x+self.y*self.bitmap.fx]
	end,
	animationStarted = instance.event,
	animationEnded = instance.event,
	animationStopped = instance.event
})