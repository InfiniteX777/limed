--[[ Classes ]
map
map:tile
]]

--[[ map ]
Inherits: instance

Description: A map sheet that can contain tile objects, entity objects and projectile objects.

Properties:
	Integer x - size x.
	Integer y - size y.
	Integer size - size per tile.
	sprite bgImage - background image.
	Integer bgParallax - background's distance from the screen.
	sprite maskImage - top-most image.
	Integer maskParallax - mask's distance from the screen.

Functions:
	tile+nil getTile( - returns the tile object on the given coordinates. nil if none.
		Integer x - coordinate x.
		Integer y - coordinate y.
	)
	nil addTile( - adds a tile object to the map.
		tile tile - tile object.
		Integer x - coordinate x.
		Integer y - coordinate y.
	)
	nil remTile( - removes the tile on the given coordinates. Nothing happens if there are no tiles.
		Integer x - coordinate x.
		Integer y - coordinate y.
	)
	nil update( - updates the map.
		Number dt - elapsed time.
	)
	nil draw( - draws the map.
		Integer x - position x from top-left.
		Integer y - position y from top-left.
		Number angle - rotation.
		Number sx - scale x.
		Number sy - scale y.
	)
]]
local map = instance:class("map",3)({
	x = 32,
	y = 32,
	size = 32,
	bgImage = nil,
	bgParallax = 10,
	maskImage = nil,
	maskParallax = 10,
	getTile = function(self,x,y)
		if self.tile then
			return self.tile[x+y*self.x]
		else self.tile = {}
		end
	end,
	addTile = function(self,tile,x,y)
		if not self.tile then
			self.tile = {}
		end
		if tile:is("tile") and x >= 0 and y >= 0 and x < self.x and y < self.y then
			self.tile[x+y*self.x] = tile
		end
	end,
	remTile = function(self,x,y)
		if not self.tile then
			self.tile = {}
		end
		self.tile[x+y*self.x] = nil
	end,
	update = function(self,dt)
		-- Background
		if self.bgImage then
			self.bgImage:update(dt,self.bgParallax)
		end
		-- Entity
		if not self.entity then
			self.entity = {}
		end
		for _,v in pairs(self.entity) do
			v:update(dt)
		end
		-- Tile
		local list = {}
		if not self.tile then
			self.tile = {}
		end
		for _,v in pairs(self.tile) do
			if v and not list[v.image] then
				list[v.image] = true
				v.image:update(dt)
			end
		end
		-- Mask
		if self.maskImage then
			self.maskImage:update(dt,self.maskParallax)
		end
	end,
	draw = function(self,x,y,angle,sx,sy)
		-- Background
		if self.bgImage then
			self.bgImage:draw(0,0,angle,sx,sy)
		end
		-- Entity
		if not self.entity then
			self.entity = {}
		end
		for _,v in pairs(self.entity) do
			v:draw(x,y,angle,sx,sy)
		end
		-- Tile
		if not self.tile then
			self.tile = {}
		end
		for i,v in pairs(self.tile) do
			local w = (i%self.x)*self.size+(self.size-v.image.bitmap.w)/2
			local h = math.floor(i/self.y)*self.size+(self.size-v.image.bitmap.h)/2
			v.image:draw(w*sx+x,h*sy+y,angle,sx,sy)
		end
		if self.maskImage then
			self.maskImage:draw(0,0,angle,sx,sy)
		end
	end
})

--[[ tile ]
Inherits: instance

Description: A tile object for the map object.

Properties:
	sprite image - sprite object.
	Boolean visible - will be drawn if true.
	Boolean collision - considered in raycasting if true.
	Number opacity - alpha value (0-1) of the image.
]]
local tile = instance:class("tile",3)({
	image = nil,
	visible = true,
	collision = true,
	opacity = 1
})