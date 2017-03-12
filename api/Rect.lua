local max,min,huge,abs = math.max,math.min,math.huge,math.abs
local prop = {"center","corner"}

local function reset(self,k)
	if k == "x" or k == "y" then
		self.position = nil
	end
	if k == "w" or k == "h" then
		self.area = nil
		self.size = nil
	end
	for _,v in pairs(prop) do
		self[v] = nil
	end
end

Rect = Instance:api{
	new = function(self,x,y,w,h,rotation)
		self:set(
			x or 0,
			y or 0,
			w or 0,
			h or 0,
			rotation or 0
		)
	end,
	__eq = function(a,b)
		return a.x == b.x and a.y == b.y and a.w == b.w and a.h == b.h and a.rotation == b.rotation
	end,
	__index = function(self,k,v)
		if not v then
			if k == "position" then
				v = Vector2:new(self.x,self.y)
				self.position = v
			elseif k == "size" then
				v = Vector2:new(self.w,self.h)
				self.size = v
			elseif k == "area" then
				v = self.w*self.h
				self.area = v
			elseif k == "center" then
				v = self.position+self.size/2
				self.center = v
			elseif k == "corner" then
				local position,size,rotation,center = self.position,self.size,self.rotation,self.center

				v = {
					position:rotate(center,rotation), -- top left
					Vector2:new(position.x+size.x,position.y):rotate(center,rotation), -- top right
					(position+size):rotate(center,rotation), -- bottom right
					Vector2:new(position.x,position.y+size.y):rotate(center,rotation) -- bottom left
				}
				self.corner = v
			end
		end

		return v
	end,
	__newindex = function(self,k,v)
		if (k == "x" or k == "y" or k == "w" or k == "h" or k == "r") and self[k] ~= v then
			reset(self,k)
		end

		return v
	end,
	__tostring = function(self)
		return "["..tostring(self.position).."], ["..tostring(self.size).."], "..self.rotation
	end,
	set = function(self,x,y,w,h,rotation)
		self.x = x or self.x
		self.y = y or self.y
		self.w = w or self.w
		self.h = h or self.h
		self.rotation = rotation or self.rotation
	end,
	axis = function(a)
		local b = a.corner
		return {
			(b[2]-b[1]).unit,
			(b[4]-b[1]).unit
		}
	end,
	collide = function(a,b)
		local c1,c2 = a.corner,b.corner
		local axis = {unpack(a:axis()),unpack(b:axis())}
		local scalar = {}
		local mtv = Vector2:new(huge,huge)

		for i=1,#axis do
			for k,v in pairs({c1,c2}) do
				scalar[k] = {}
				for _,point in pairs(v) do
					table.insert(scalar[k],point:dot(axis[i]))
				end
			end
			local amax,amin = max(unpack(scalar[1])),min(unpack(scalar[1]))
			local bmax,bmin = max(unpack(scalar[2])),min(unpack(scalar[2]))
			if bmin >= amax or bmax <= amin then
				return false,Vector2:new()
			end
			local overlap = amax > bmax and -(bmax-amin) or (amax-bmin)
			if abs(overlap) < mtv.mag then
				mtv = axis[i]*overlap
			end
		end

		return true,mtv
	end,
	contains = function(a,...)
		local res = true
		for _,b in pairs({...}) do
			if b:type() == "Vector2" then
				b = b:rotateToVectorSpace(a.center,-a.rotation)
				local c,d = a.position,a.position+a.size
				res = c.x <= b.x and b.x <= d.x and c.y <= b.y and b.y <= d.y
			else b = b:clone()
				b.rotation = b.rotation-a.rotation
				local corner = b.corner
				res = a:contains(unpack(b.corner))
			end
			if not res then
				return false
			end
		end
		return true
	end,
	components = function(self)
		return self.x,self.y,self.w,self.h,self.rotation
	end,
	clone = function(self)
		return Rect:new(self.dposition,self.dsize,self.drotation)
	end
}
