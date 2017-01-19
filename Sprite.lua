local cache = {}

--[[ Dependency ]
ContentService
]]

--[[ Image ]
Inherits: Instance

Description: Creates an image. Can only be created via 'ContentService:loadImage()'.

Properties:
	love:Image image - Image source.
	Color color - Image color.
	Integer width - Image width.
	Integer height - Image height.

Functions:
	nil draw(...) - Draws the image.
]]
local Image = Instance:class("Image",4)({
	image = nil,
	color = Color:new(255,255,255),
	width = 0,
	height = 0,
	draw = function(self,...)
		if self.image then
			love.graphics.setColor(self.color:components())
			love.graphics.draw(self.image,...)
		end
	end
})

--[[ Bitmap ]
Inherits: Image

Description: Creates a bitmap sheet, a collection of 'Quad' objects. All bitmaps are stored and recycled.
			 Starting frame is [0,0].

Properties:
	Integer fx (read-only) - Number of frames from left to right.
	Integer fy (read-only) - Number of frames from top to bottom.
	Table+nil sheet (read-only) - A list of frames of the bitmap. Needs to use 'bake' function first or it will return nil.

Functions:
	nil bake( - Creates a frame sheet.
		String source - image path.
		Integer width - width pixels per frame.
		Integer height - height pixels per frame.
	)

	Quad get( - Gets a frame from the bitmap's frame sheet.
		Integer x - frame x.
		Integer y - frame y.
	) - Returns Quad object.

	Sprite sprite( - Creates an animated image with this bitmap.
		function prop - Properties for direct changes.
	) - Returns Sprite object.
]]
local Bitmap = Image:class("Bitmap",3)({
	fx = 0,
	fy = 0,
	sheet = {},
	bake = function(self,source,w,h)
		if cache[w] and cache[w][h] and cache[w][h][source] then
			self.image = cache[w][h][source].image
			self.sheet = cache[w][h][source].sheet
		else cache[w] = cache[w] or {}
			cache[w][h] = cache[w][h] or {}
			cache[w][h][source] = {}
			self.image = Instance:service("ContentService"):loadImage(source).image
			local imgw = self.image:getWidth()
			local imgh = self.image:getHeight()
			self.width = w or imgw
			self.height = h or imgh
			self.fx = math.floor(imgw/self.width)
			self.fy = math.floor(imgh/self.height)
			for x=0,self.fx-1 do
				for y=0,self.fy-1 do
					self.sheet[x+y*self.fx] = love.graphics.newQuad(x*self.width,y*self.height,self.width,self.height,imgw,imgh)
				end
			end
			cache[w][h][source].image = self.image
			cache[w][h][source].sheet = self.sheet
		end
	end,
	get = function(self,x,y)
		x = x or 0
		y = y or 0
		if not self.image or not self.sheet[x+y*self.fx] then return end

		return self:new("Quad",function(t)
			t.frame = self.sheet[x+y*self.fx]
			t.bitmap = self
			t.width = self.width
			t.height = self.height
		end)
	end,
	sprite = function(self,prop)
		return self:new("Sprite",prop)
	end,
	__draw = true
})

--[[ Quad ]
Inherits: Bitmap

Description: A frame from a bitmap.

Properties:
	love:Quad frame (read-only) - A cropped out image.
	Bitmap bitmap - A bitmap source.

Functions:
	nil draw( - Draws the current frame.
		Integer x - Pixel from left to right.
		Integer y - Pixel from top to bottom.
		Number angle - image rotation.
		Number sx - scale x.
		Number sy - scale y.
	)
]]
local Quad = Bitmap:class("Quad",4)({
	frame = nil,
	draw = function(self,x,y,angle,sx,sy)
		if self.frame then
			local c = self.color*self.color
			love.graphics.setColor(c.r,c.g,c.b,c.a)
			love.graphics.draw(self.image,self.frame,x,y,angle,sx,sy)
		end
	end
})

--[[ Sprite ]
Inherits: Quad

Description: An animation composed of quad objects.

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
local Sprite = Quad:class("Sprite",4)({
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
						self.x = self.playing and self.startFrame or self.endFrame
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
	animationStarted = Instance.event,
	animationEnded = Instance.event,
	animationStopped = Instance.event
})