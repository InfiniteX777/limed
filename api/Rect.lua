local prop = {"center","corner"}

local function merge(a,b)
	local c = getmetatable(a)
	for k,v in pairs(b) do
		local f = c[k]
		c[k] = function(...)
			if f then
				f(...)
			end
			b[k](...)
		end
	end
	return a
end

local function reset(self,i)
	if i == "size" then
		rawset(self,"area",nil)
	end
	for _,v in pairs(prop) do
		rawset(self,v,nil)
	end
end

Rect = {
	__index = function(self,i)
		if i == "size" or i == "position" then
			return merge(rawget(self,"d"..i),{
				__newindex = function(t,k,v)
					if k == "x" or k == "y" then
						rawset(t,"d"..k,math.max(0,v))
						reset(self,i)
					end
				end
			})
		elseif i == "rotation" then
			return rawget(self,"drotation")
		elseif i == "area" then
			rawset(self,"area",rawget(self.size,"dx")*rawget(self.size,"dy"))
			return rawget(self,"area")
		elseif i == "center" then
			rawset(self,"center",rawget(self,"dposition")+rawget(self,"dsize")/2)
			return rawget(self,"center")
		elseif i == "corner" then
			local position = rawget(self,"dposition")
			local size = rawget(self,"dsize")
			rawset(self,"corner",{
				position:rotateToVectorSpace(self.center,self.rotation), -- top left
				Vector2:new(position.x+size.x,position.y):rotateToVectorSpace(self.center,self.rotation), -- top right
				(position+size):rotateToVectorSpace(self.center,self.rotation), -- bottom right
				Vector2:new(position.x,position.y+size.y):rotateToVectorSpace(self.center,self.rotation) -- bottom left
			})
			return rawget(self,"corner")
		end
	end,
	__newindex = function(self,i,v)
		if (i == "position" or i == "size" or i == "rotation") and self["d"..i] ~= v then
			rawset(self,i,nil)
			if i == "size" then
				v = Vector2:new(math.max(0,v.dx),math.max(0,v.dy))
			end
			rawset(self,"d"..i,v)
			reset(self,i)
		end
	end,
	__tostring = function(self)
		local center = self.center
		return "["..tostring(self.dposition).."], ["..tostring(self.dsize).."], "..self.drotation
	end
}

function Rect:new(position,size,rotation)
	return setmetatable({
		dposition = position or Vector2:new(),
		dsize = size and Vector2:new(math.max(0,size.dx),math.max(0,size.dy)) or Vector2:new(),
		drotation = rotation or 0,
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
			local mtv = Vector2:new(math.huge,math.huge)

			for i=1,#axis do
				for k,v in pairs({c1,c2}) do
					scalar[k] = {}
					for _,point in pairs(v) do
						table.insert(scalar[k],point:dot(axis[i]))
					end
				end
				local amax,amin = math.max(unpack(scalar[1])),math.min(unpack(scalar[1]))
				local bmax,bmin = math.max(unpack(scalar[2])),math.min(unpack(scalar[2]))
				if bmin >= amax or bmax <= amin then
					return false,Vector2:new()
				end
				local overlap = amax > bmax and -(bmax-amin) or (amax-bmin)
				if math.abs(overlap) < mtv.mag then
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
		end,
		clone = function(self)
			return Rect:new(self.dposition,self.dsize,self.drotation)
		end,
		type = function()
			return "Rect"
		end
	},Rect)
end
