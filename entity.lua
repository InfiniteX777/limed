require("lemonsquare")

local cache = {}
entity = {}
entity.__index = entity

--[[
Creates an entity.
Called by: root

sprite:animate sprite - sprite sheet of the entity.
Number w - width of the entity.
Number h - height of the entity.

return entity.
]]
function entity:new(sprite,w,h)
	local t = {
		sprite = sprite,
		hitbox = vec2:new(w,h),
		position = vec2:new(),
		velocity = vec2:new()
	}

	return setmetatable(t,entity)
end

--[[
Checks if the entity is standing on a tile.

map map - map being simulated.

return tile+nil - tile intersected. nil if none.
	   vec2 - intersected point. returns the entity's lowest point if none are intersected.
]]
function entity:isGrounded(map)
	local r = ray:new(position,vec2:new(0,-1),hitbox.y/2)

	return r:hit(map)
end

--[[
Pushes the entity (increases it's velocity).

vec2 v - force in pixels per second.
]]
function entity:push(v)
	self.velocity = self.velocity+v
end

--[[
Updates the entities state (velocity, position and animation).

Number dt - delta time.
]]
function entity:update(dt)
end

--[[
Draws the entity's sprite.

Number x - position x.
Number y - position y.
Number angle - rotation.
Number sx - scale x.
Number sy - scale y.
]]
function entity:draw(x,y,angle,sx,sy)
	self.sprite:draw(self.position.x+x,self.position.y+y,angle,sx,sy)
end