-- Miscellaneous

lemon = {}
lemon.__index = lemon

function lemon.clamp(a,b,v)
	return math.max(a or 0,math.min(v or 0,b or 0))
end

-- Vector2

Vector2 = {
	__add = function(a,b)
		if type(b) == "table" then
			return Vector2:new(a.x+b.x,a.y+b.y)
		end
		return Vector2:new(a.x+b,a.y+b)
	end,
	__sub = function(a,b)
		if type(b) == "table" then
			return Vector2:new(a.x-b.x,a.y-b.y)
		end
		return Vector2:new(a.x-b,a.y-b)
	end,
	__mul = function(a,b)
		if type(b) == "table" then
			return Vector2:new(a.x*b.x,a.y*b.y)
		end
		return Vector2:new(a.x*b,a.y*b)
	end,
	__div = function(a,b)
		if type(b) == "table" then
			return Vector2:new(a.x/b.x,a.y/b.y)
		end
		return Vector2:new(a.x/b,a.y/b)
	end,
	__mod = function(a,b)
		if type(b) == "table" then
			return Vector2:new(a.x%b.x,a.y%b.y)
		end
		return Vector2:new(a.x%b,a.y%b)
	end,
	__pow = function(a,b)
		if type(b) == "table" then
			return Vector2:new(a.x^b.x,a.y^b.y)
		end
		return Vector2:new(a.x^b,a.y^b)
	end,
	__unm = function(a)
		return Vector2:new(-a.x,-a.y)
	end,
	__eq = function(a,b)
		if type(b) == "table" then
			return a.x == b.x and a.y == b.y
		end
		return false
	end,
	__lt = function(a,b)
		if type(b) == "table" then
			return a.mag < b.mag
		end
		return false
	end,
	__le = function(a,b)
		if type(b) == "table" then
			return a.mag <= b.mag
		end
		return false
	end,
	__index = function(self,i)
		if i == "x" or i == "y" then
			return rawget(self,"d"..i)
		elseif i == "unit" then
			rawset(self,"unit",Vector2:new(self.dx,self.dy)/self.mag)
			return rawget(self,"unit")
		elseif i == "mag" then
			rawset(self,"mag",(self.dx^2+self.dy^2)^0.5)
			return rawget(self,"mag")
		end
	end,
	__newindex = function(self,i,v)
		if (i == "x" or i == "y") and self["d"..i] ~= v then
			rawset(self,i,nil)
			rawset(self,"d"..i,v)
			rawset(self,"unit",nil)
			rawset(self,"mag",nil)
		end
	end,
	__tostring = function(self)
		return self.dx..", "..self.dy
	end
}

--[[ Vector2 ]
Creates a reference of 2 vectors.

Properties:
	Number x - vector x.
	Number y - vector y.

Functions:
	Number dot( - Dot product from this vector to the provided scalar Vector2.
		Vector2 b - Scalar Vector2.
	) - Returns the dot product.

	Vector2 lerp( - Linear interpolation. Transitions the current Vector2 to the provided Vector2 linearly.
		Vector2 b - End point.
		Number d - Delta scale (0-1.0).
	) - Returns a*(1-d)+b*d

	Vector2, Vector2 rect( - Returns 2 new Vector2s arranged so that it forms a proper rectangle.
		Vector2 b - Reference Vector2.
	) - Returns two Vector2s. The first is the top-left point for the rectangle, and the second is the bottom-right point.

	Number, Number components() - Returns all of the components. Order is X and Y.

	Vector2 clone() - Creates a direct copy of this object.
]]
function Vector2:new(x,y)
	return setmetatable(
		{
			dx = x or 0,
			dy = y or 0,
			dot = function(a,b)
				return a.dx*b.dx+a.dy*b.dy
			end,
			lerp = function(a,b,d)
				d = math.max(0,math.min(d or 0,1))
				return a*(1-d)+b*d
			end,
			rect = function(a,b)
				local v1,v2 = b.x < a.x, b.y < a.y
				return Vector2:new(v1 and b.x or a.x,v2 and b.y or a.y), Vector2:new(v1 and a.x or b.x,v2 and a.y or b.y)
			end,
			components = function(self)
				return self.dx,self.dy
			end,
			clone = function(self)
				return Vector2:new(self.dx,self.dy)
			end
		},
		Vector2
	)
end

-- Raycast

Ray = {}
Ray.__index = Ray

--[[
Creates a new ray.

Vector2 o - origin. Starting point of the ray.
Vector2 d - direction. Directional vector of the ray.

return Ray
]]
function Ray:new(o,d)
	b = b.unit

	local t = {
		origin = a,
		direction = b.unit
	}

	return setmetatable(t,Ray)
end

--[[
Returns the closest point of the ray's direction to the given point.

Vector2 v - reference point.

return Vector2 - closest point.
]]
function Ray:closest(v)
	local p = v-self.origin
	local delta = math.max(0,p.unit:dot(self.direction))

	return self.origin+self.direction*p.mag*delta
end

--[[
Tries to intersect a circle with a ray, otherwise returns nil.
Called by: Ray

Number dis - total length of the ray.
Vector2 v - position of the circle.
Number r - radius of the circle.

return Vector2+nil - the intersected point on the circle. Will return nil if not intersected.
]]
function Ray:circleIntersect(dis,v,r)
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
Called by: Ray

map map - the map being simulated.
Number distance - Total length of the ray towards the directional vector.
Vector2 origin - starting point.
Vector2 offset - tile coordinate from the starting point.
Vector2 root - displacement from the Vector2:(0,0).

return tile+nil - the intersected tile from the origin. nil if none.
	   Vector2 - the point that intersected the tile. returns the end point if none are intersected.
]]
function Ray:hit(map,distance,origin,offset,root)
	local angle = math.atan2(self.direction.y,self.direction.x)
	local sin = math.sin(angle)
	local cos = math.cos(angle)
	origin = origin or self.origin:clone()
	distance = distance or self.distance/map.scale
	offset = offset or Vector2:new(
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
			pos = Vector2:new(origin.y,origin.x)
		end
		if cos == 0 then return huge end
		local dx = run > 0 and math.floor(pos.x+1)-pos.x or math.ceil(pos.x-1)-pos.x
		local dy = dx*(rise/run)

		return invert and Vector2:new(dy,dx) or Vector2.new(dx,dy)
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
		else return self:hit(map,distance-d.mag,origin,offset,root)
		end
	else return nil,(origin+direction*distance)*size-root
	end
end