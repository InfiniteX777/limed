local max,abs = math.max,math.abs

local Entity = Instance:class("Entity",3)({
	sprite = nil,
	hitbox = Vector2:new(),
	position = Vector2:new(),
	velocity = Vector2:new(),
	motion = 0,
	gravity = 9.81*2,
	map = nil,
	ground = nil,
	rect = function()
		return Rect:new(
			self.position-Vector2:new(self.hitbox.x/2,self.hitbox.y),
			self.position+Vector2:new(self.hitbox/2,0)
		)
	end,
	push = function(self,v)
		self.velocity = self.velocity+v
	end,
	update = function(self,dt)
		local p = self.position-Vector2:new(0,self.hitbox.y/2)
		local x = (self.velocity.x-self.motion*dt)*dt
		local y = -self.gravity*dt

		-- horizontal
		if self.velocity.x ~= 0 then
			local u = self.velocity.x/abs(self.velocity.x)
			local tile,hit = Line:new(p,p+Vector2:new(self.velocity.x+self.hitbox.y/2*u,0)):mapIntersect(self.map)
			if tile then
				self.position.x = hit.x-self.hitbox.x/2*u
				self.velocity.x = -self.velocity.x/2
				x = -x
			end
		end

		-- vertical
		local u = self.velocity.y < 0 and -1 or 0
		local tile,hit = Line:new(p,self.position+Vector2:new(0,self.velocity.y+self.hitbox.y*u)):mapIntersect(self.map)
		if tile then
			self.position.y = hit.y-self.hitbox.y*u
			if u == 0 then
				x = (self.velocity.x-self.motion*dt)*tile.friction
				y = max(0,self.velocity.y)
			else self.velocity.y = -self.velocity.y/2
			end
		end
		self.ground = u == 0 and tile or nil

		self.velocity = self.velocity-Vector2:new(x,y)
		self.position = self.position+self.velocity
		self.position = Vector2:new(max(self.hitbox.x/2,self.position.x),max(self.hitbox.y,self.position.y))
	end,
	draw = function(self,x,y,angle,sx,sy)
		local pos = self.position-Vector2:new(self.sprite.width/2,self.sprite.height)
		self.sprite:draw(pos.x*sx+x,pos.y*sy+y,angle,sx,sy)
	end
})