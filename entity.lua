--[[ entity]
Inherits: instance

Description: An animated rigid body.

Properties:
	sprite sprite - The visual representation of the entity.
	vec2 hitbox - Size of the entity in pixels.
				  Width (vector x) is central to the entity's position,
				  while height (vector y) goes upward from the entity's position.
	vec2 position - Location of the entity on map's space.
	vec2 velocity - current speed in pixels per second.

Functions:
	tile+nil isGrounded( - Checks if a tile is directly beneath the entity.
		map map - The simulated map.
	) - Returns an intersected tile, otherwise returns nil.
	nil push( - Increases the entity's velocity.
		vec2 v - reference.
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

sprite:animate sprite - sprite sheet of the entity.
Number w - width of the entity.
Number h - height of the entity.

return entity.
]]
local entity = instance:class("entity",3)({
	sprite = nil,
	hitbox = vec2:new(),
	position = vec2:new(),
	velocity = vec2:new(),
	isGrounded = function(self,map)
		local r = ray:new(position,vec2:new(0,-1),self.hitbox.y/2)

		return r:hit(map)
	end,
	push = function(self,v)
		self.velocity = self.velocity+v
	end,
	update = function(self,dt)
		self.position = self.position+self.velocity
		self.velocity = self.velocity*dt
	end,
	draw = function(self,x,y,angle,sx,sy)
		self.sprite:draw(self.position.x+x,self.position.y+y,angle,sx,sy)
	end
})