local max,min,cos,sin = math.max,math.min,math.cos,math.sin

Vector2 = Instance:api({
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
		if type(a) == "number" then
			a = Vector2:new(a,a)
		end
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
		elseif i == "perpendicular" then
			rawset(self,"perpendicular",Vector2:new(self.dy,-self.dx).unit)
			return rawget(self,"perpendicular")
		end
	end,
	__newindex = function(self,i,v)
		if (i == "x" or i == "y") and self["d"..i] ~= v then
			rawset(self,i,nil)
			rawset(self,"d"..i,v)
			rawset(self,"unit",nil)
			rawset(self,"mag",nil)
			rawset(self,"perpendicular",nil)
		end
		if self.__callback then
			self.__callback(self,i,v)
		end
	end,
	__tostring = function(self)
		return self.dx..", "..self.dy
	end
},{
	dot = function(a,b)
		return a.dx*b.dx+a.dy*b.dy
	end,
	cross = function(a,b)
		return a.dx*b.dy-a.dy*b.dx
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
	rotateToVectorSpace = function(a,b,r)
		return Vector2:new(
			b.x + (a.x-b.x)*cos(r) - (a.y-b.y)*sin(r),
			b.y + (a.x-b.x)*sin(r) + (a.y-b.y)*cos(r)
		)
	end,
	components = function(self)
		return self.dx,self.dy
	end,
	clone = function(self)
		return Vector2:new(self.dx,self.dy)
	end,
	type = function()
		return "Vector2"
	end
},function(self,x,y)
	self.x = x or 0
	self.y = y or 0
end)