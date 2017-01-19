--[[ Ray ]
Description: An invisible line to intersect objects with.

Properties:
	Vector2 o - origin. Starting point of the ray.
	Vector2 d - direction. Directional vector of the ray.

Functions:
	Vector2 closest( - Returns the closest point of the ray's direction to the given point.
		Vector2 v - reference point.
	) - Returns the closest point.

	Vector2+nil circleIntersect( - Tries to intersect a circle with a ray.
		Number dis - total length of the ray.
		Vector2 v - position of the circle.
		Number r - radius of the circle.
	) - Returns the point if it is intersected, otherwise nil.

	Tile+nil, Vector2 hit( - Simulates the ray in a map's space.
		map map - the map being simulated.
		Number distance - Total length of the ray towards the directional vector.
	) - Returns the tile that was intersected and the point of intersection.
		'Tile' is nil and the point is at the end of the ray if none are intersected.
]]
Ray = {}
Ray.__index = Ray

function Ray:new(o,d)
	d = d.unit

	local t = {
		origin = o,
		direction = d.unit
	}

	return setmetatable(t,Ray)
end

function Ray:closest(v)
	local p = v-self.origin
	local delta = math.max(0,p.unit:dot(self.direction))

	return self.origin+self.direction*p.mag*delta
end

function Ray:circleIntersect(dis,v,r)
	local p = self:closest(v)
	if (p-v).mag <= r then
		p = p-self.direction*math.sqrt(r^2-(p-self.origin).mag^2)
		if (p-self.origin).mag <= dis then
			return p
		end
	end
end

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