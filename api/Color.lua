local floor = math.floor

local properties = {"r","g","b","a"}
for k,v in pairs(properties) do
	properties[v] = true
end

local function clamp(r,g,b,a)
	r = r and lemon.clamp(floor(r)) or nil
	g = g and lemon.clamp(floor(g)) or nil
	b = b and lemon.clamp(floor(b)) or nil
	a = a and lemon.clamp(floor(a)) or nil
	return r,g,b,a
end

Color = Instance:api{
	new = function(self,r,g,b,a)
		self:set(r or 0,g or 0,b or 0,a or 255)
	end,
	set = function(self,r,g,b,a)
		self.r = r or self.r
		self.g = g or self.g
		self.b = b or self.b
		self.a = a or self.a
	end,
	__add = function(a,b)
		if type(b) == "table" then
			return Color:new(clamp(a.r+b.r,a.g+b.g,a.b+b.b,a.a+b.a))
		end
		return Color:new(clamp(a.r+b,a.g+b,a.b+b,a.a))
	end,
	__sub = function(a,b)
		if type(b) == "table" then
			return Color:new(clamp(a.r-b.r,a.g-b.g,a.b-b.b,a.a-b.a))
		end
		return Color:new(clamp(a.r-b,a.g-b,a.b-b,a.a))
	end,
	__mul = function(a,b)
		return Color:new(clamp(a.r*b.r/255,a.g*b.g/255,a.b*b.b/255,a.a*b.a/255))
	end,
	__div = function(a,b)
		return Color:new(clamp(a.r/b.r*255,a.g/b.g*255,a.b/b.b*255,a.a/b.a*255))
	end,
	__pow = function(a,b)
		if type(b) == "table" then
			return Color:new(clamp(a.r^b.r,a.g^b.g,a.b^b.b,a.a^b.a))
		end
		return Color:new(clamp(a.r^b,a.g^b,a.b^b,a.a))
	end,
	__eq = function(a,b)
		if type(b) == "table" then
			return a.r == b.r and a.g == b.g and a.b == b.b and a.a == b.a
		end
		return false
	end,
	__tostring = function(self)
		return self.r..", "..self.g..", "..self.b..", "..self.a
	end,
	components = function(self)
		return self.r,self.g,self.b,self.a
	end,
	clone = function(self)
		return Color:new(self.r,self.g,self.b,self.a)
	end
}
