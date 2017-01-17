-- Vector2

vec2 = {
	__add = function(a,b)
		if type(b) == "table" then
			return vec2:new(a.x+b.x,a.y+b.y)
		end
		return vec2:new(a.x+b,a.y+b)
	end,
	__sub = function(a,b)
		if type(b) == "table" then
			return vec2:new(a.x-b.x,a.y-b.y)
		end
		return vec2:new(a.x-b,a.y-b)
	end,
	__mul = function(a,b)
		if type(b) == "table" then
			return vec2:new(a.x*b.x,a.y*b.y)
		end
		return vec2:new(a.x*b,a.y*b)
	end,
	__div = function(a,b)
		if type(b) == "table" then
			return vec2:new(a.x/b.x,a.y/b.y)
		end
		return vec2:new(a.x/b,a.y/b)
	end,
	__mod = function(a,b)
		if type(b) == "table" then
			return vec2:new(a.x%b.x,a.y%b.y)
		end
		return vec2:new(a.x%b,a.y%b)
	end,
	__pow = function(a,b)
		if type(b) == "table" then
			return vec2:new(a.x^b.x,a.y^b.y)
		end
		return vec2:new(a.x^b,a.y^b)
	end,
	__unm = function(a)
		return vec2:new(-a.x,-a.y)
	end,
	__eq = function(a,b)
		if type(b) == "table" then
			return a.x == b.x and a.y == b.y
		end
		return false
	end,
	__lt = function(a,b)
		if type(b) == "table" then
			return a.x < b.x and a.y < b.y
		end
		return false
	end,
	__le = function(a,b)
		if type(b) == "table" then
			return a.x <= b.x and a.y <= b.y
		end
		return false
	end,
	__index = function(self,i)
		if i == "x" or i == "y" then
			return rawget(self,"d"..i)
		elseif i == "unit" then
			rawset(self,"unit",vec2:new(self.dx,self.dy)/self.mag)
			return rawget(self,"unit")
		elseif i == "mag" then
			rawset(self,"mag",(self.dx^2+self.dy^2)^0.5)
			return rawget(self,"mag")
		end
	end,
	__newindex = function(self,i,v)
		if (i == "x" or i == "y") and self["d"..i] ~= v then
			rawset(self,i,nil)
			self["d"..i] = v
			self.unit = nil
			self.mag = nil
		end
	end,
	__tostring = function(self)
		return self.x..", "..self.y
	end
}

--[[
Creates a collection of 2 vectors.

Number x - vector x.
Number y - vector y.

return vec2
]]
function vec2:new(x,y)
	local t = {
		dx = x or 0,
		dy = y or 0,
		dot = function(a,b)
			return a.dx*b.dx+a.dy*b.dy
		end,
		lerp = function(a,b,d)
			d = math.max(0,math.min(d or 0,1))
			return a*(1-d)+b*d
		end,
		clone = function(a)
			return vec2:new(a.dx,a.dy)
		end
	}

	return setmetatable(t,vec2)
end

-- Raycast

ray = {}
ray.__index = ray

--[[
Creates a new ray.
Called by: root

vec2 o - origin. Starting point of the ray.
vec2 d - direction. Directional vector of the ray.

return ray
]]
function ray:new(o,d)
	b = b.unit

	local t = {
		origin = a,
		direction = b.unit
	}

	return setmetatable(t,ray)
end

--[[
Returns the closest point of the ray's direction to the given point.

vec2 v - reference point.

return vec2 - closest point.
]]
function ray:closest(v)
	local p = v-self.origin
	local delta = math.max(0,p.unit:dot(self.direction))

	return self.origin+self.direction*p.mag*delta
end

--[[
Tries to intersect a circle with a ray, otherwise returns nil.
Called by: ray

Number dis - total length of the ray.
vec2 v - position of the circle.
Number r - radius of the circle.

return vec2+nil - the intersected point on the circle. Will return nil if not intersected.
]]
function ray:circleIntersect(dis,v,r)
	local p = self:closest(v)
	if (p-v).mag <= r then
		p = p-self.direction*math.sqrt(r^2-(p-self.origin).mag^2)
		if (p-self.origin).mag <= dis then
			return p
		end
	end
end

--[[
Simulates the ray in map's space. Only the map and distance is required, the remaining parameters are supplied automatically.
Called by: ray

map map - the map being simulated.
Number distance - Total length of the ray towards the directional vector.
vec2 origin - starting point.
vec2 offset - tile coordinate from the starting point.
vec2 root - displacement from the vec2:(0,0).

return tile+nil - the intersected tile from the origin. nil if none.
	   vec2 - the point that intersected the tile. returns the end point if none are intersected.
]]
function ray:hit(map,distance,origin,offset,root)
	local angle = math.atan2(self.direction.y,self.direction.x)
	local sin = math.sin(angle)
	local cos = math.cos(angle)
	origin = origin or self.origin:clone()
	distance = distance or self.distance/map.scale
	offset = offset or vec2:new(
		math.floor(origin.x)-(origin.x%1 == 0 and cos < 0 and 1 or 0),
		math.floor(origin.y)-(origin.y%1 == 0 and sin < 0 and 1 or 0)
	)
	root = root or origin
	n = n+1

	local function delta(invert)
		local rise,run,pos = sin,cos,origin:clone()
		if invert then
			rise = cos
			run = sin
			pos = vec2:new(origin.y,origin.x)
		end
		if cos == 0 then return huge end
		local dx = run > 0 and math.floor(pos.x+1)-pos.x or math.ceil(pos.x-1)-pos.x
		local dy = dx*(rise/run)

		return invert and vec2:new(dy,dx) or Vector2.new(dx,dy)
	end

	local dx,dy = delta(),delta(true)
	local d = dx
	local sx = d.x < 0 and -1 or 1
	local sy = 0

	if dx.mag > dy.mag then
		d = dy
		sx = 0
		sy = d.y < 0 and -1 or 1
	end

	if d.mag < distance then
		offset = offset+Vector2.new(sx,sy)
		square(Vector3.new(
			offset.x*size,
			0,
			offset.y*size
		))
		render(Color3.new(1,0,0),Vector3.new(d.x+origin.x,0,d.y+origin.y)*size-Vector3.new(root.x,0,root.y))
		local tile = map[offset.x] and map[offset.x][offset.y]
		if tile and tile.active and tile.collision then
			return map[offset.x][offset.y],origin+d
		else return ray(map,distance-d.mag,origin,offset,root)
		end
	else return nil,(origin+direction*distance)*size-root
	end
end