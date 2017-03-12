local max,min,cos,sin = math.max,math.min,math.cos,math.sin

local function convert(...)
	local l = {...}

	for k,v in pairs(l) do
		if type(v) == "number" then
			l[k] = Vector2:new(v,v)
		end
	end

	return unpack(l)
end

Vector2 = Instance:api{
	new = function(self,x,y)
		self:set(x or 0,y or 0)
	end,
	__add = function(a,b)
		local a,b = convert(a,b)

		return Vector2:new(a.x+b.x,a.y+b.y)
	end,
	__sub = function(a,b)
		local a,b = convert(a,b)

		return Vector2:new(a.x-b.x,a.y-b.y)
	end,
	__mul = function(a,b)
		local a,b = convert(a,b)

		return Vector2:new(a.x*b.x,a.y*b.y)
	end,
	__div = function(a,b)
		local a,b = convert(a,b)

		return Vector2:new(a.x/b.x,a.y/b.y)
	end,
	__mod = function(a,b)
		local a,b = convert(a,b)

		return Vector2:new(a.x%b.x,a.y%b.y)
	end,
	__pow = function(a,b)
		local a,b = convert(a,b)

		return Vector2:new(a.x^b.x,a.y^b.y)
	end,
	__unm = function(a)
		return Vector2:new(-a.x,-a.y)
	end,
	__eq = function(a,b)
		local a,b = convert(a,b)

		return a.x == b.x and a.y == b.y
	end,
	__lt = function(a,b)
		local a,b = convert(a,b)

		return a.mag < b.mag
	end,
	__le = function(a,b)
		local a,b = convert(a,b)

		return a.mag <= b.mag
	end,
	__index = function(self,k,v)
		if not v then
			if k == "unit" then
				v = Vector2:new(self.x,self.y)/self.mag
				self.unit = v
			elseif k == "mag" then
				v = (self.x^2+self.y^2)^0.5
				self.mag = v
			elseif k == "perpendicular" then
				v = Vector2:new(self.dy,-self.dx).unit
				self.perpendicular = v
			end
		end

		return v
	end,
	__newindex = function(self,k,v)
		if (k == "x" or k == "y") and self[k] ~= v then
			local v = v or 0
			self.mag = nil
			self.unit = nil
			self.perpendicular = nil
		end

		return v
	end,
	__tostring = function(self)
		return self.x..", "..self.y
	end,
	set = function(self,x,y)
		self.x = x or self.x
		self.y = y or self.y
	end,
	dot = function(a,b)
		return a.x*b.x+a.y*b.y
	end,
	cross = function(a,b)
		return a.x*b.y-a.y*b.x
	end,
	lerp = function(a,b,d)
		d = max(0,min(d or 0,1))
		return a*(1-d)+b*d
	end,
	rect = function(a,b)
		local v1,v2 = b.x < a.x, b.y < a.y
		local c,d = Vector2:new(v1 and b.x or a.x,v2 and b.y or a.y),Vector2:new(v1 and a.x or b.x,v2 and a.y or b.y)
		return Rect:new(c,d-c)
	end,
	rotate = function(a,b,r)
		local c,d = b:components()
		local a,b = a:components()
		return Vector2:new(
			c + (a-c)*cos(r) - (b-d)*sin(r),
			d + (a-c)*sin(r) + (b-d)*cos(r)
		)
	end,
	components = function(self)
		return self.x,self.y
	end,
	clone = function(self)
		return Vector2:new(self.x,self.y)
	end
}
