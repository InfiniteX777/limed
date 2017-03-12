local floor = math.floor
local lower = string.lower

local Map = Instance:class("Map",3)({
	x = 32,
	y = 32,
	size = 32,
	gravity = Vector2:new(0,9.81*2),
	background = {
		image = nil,
		parallax = 10
	},
	mask = {
		image = nil,
		parallax = 10
	},
	entity = {},
	tile = {},
	projectile = {},
	get = function(self,x,y)
		if self.tile then
			return self.tile[x+y*self.x]
		else self.tile = {}
		end
	end,
	add = function(self,v,...)
		if v:is("Tile") then
			local x,y = ...
			if x >= 0 and y >= 0 and x < self.x and y < self.y then
				self.tile[x+y*self.x] = v
			end
		elseif v:is("Entity") then
			v.map = self
			self.entity[v] = true
		elseif v:is("Projectile") then
			v.map = self
			self.projectile[v] = true
		end
	end,
	rem = function(self,v,...)
		if type(v) == "number" then
			local y = ...
			self.tile[v+y*self.x] = nil
		elseif v:is("Entity") then
			v.map = nil
			self.entity[v] = nil
		elseif v:is("Projectile") then
			v.map = nil
			self.projectile[v] = nil
		end
	end,
	update = function(self,dt)
		-- Background
		if self.background.image then
			self.background.image:update(dt,self.background.parallax)
		end
		-- Entity
		for v,_ in pairs(self.entity) do
			v:update(dt)
		end
		-- Projectile
		for v,_ in pairs(self.projectile) do
			v:update(dt)
		end
		-- Tile
		local list = {}
		for _,v in pairs(self.tile) do
			if v and not list[v.image] then
				list[v.image] = true
				v.image:update(dt)
			end
		end
		-- Mask
		if self.mask.image then
			self.mask.image:update(dt,self.mask.parallax)
		end
	end,
	draw = function(self,x,y,angle,sx,sy,...)
		local pos,size = Vector2:new(x,y),Vector2:new(self.x,self.y)*self.size
		pos = (pos+size/2):rotateToVectorSpace(Vector2:new(),-angle)-size/2
		x,y = pos.x,pos.y
		-- Background
		if self.background.image then
			love.graphics.rotate(angle)
			self.background.image:draw(0,0,0,sx,sy)
			love.graphics.origin()
		end
		-- Entity
		for v,_ in pairs(self.entity) do
			love.graphics.rotate(angle)
			v:draw(x,y,0,sx,sy)
			love.graphics.origin()
		end
		-- Projectile
		for v,_ in pairs(self.projectile) do
			love.graphics.rotate(angle)
			v:draw(x,y,0,sx,sy)
			love.graphics.origin()
		end
		-- Tile
		for i,v in pairs(self.tile) do
			local w = (i%self.x)*self.size+(self.size-v.image.width)/2
			local h = floor(i/self.y)*self.size+(self.size-v.image.height)/2
			love.graphics.rotate(angle)
			v.image:draw(w*sx+x,h*sy+y,0,sx,sy)
			love.graphics.origin()
		end
		if self.mask.image then
			love.graphics.rotate(angle)
			self.mask.image:draw(0,0,0,sx,sy)
		end
		love.graphics.origin()
	end
})

local Tile = Instance:class("Tile",3)({
	image = nil,
	visible = true,
	collision = true,
	friction = 0.2
})