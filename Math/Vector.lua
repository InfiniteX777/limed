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