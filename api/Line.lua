local max,sqrt,floor,huge = math.max,math.sqrt,math.floor,math.huge

Line = Instance:api({
	__index = function(self,i)
		if i == "a" or i == "b" then
			return rawget(self,"d"..i)
		elseif i == "direction" then
			rawset(self,"direction",(self.db-self.da).unit)
			return rawget(self,"direction")
		elseif i == "mag" then
			rawset(self,"mag",(self.db-self.da).mag)
			return rawget(self,"mag")
		end
	end,
	__newindex = function(self,i,v)
		if (i == "a" or i == "b") and self["d"..i] ~= v then
			rawset(self,i,nil)
			rawset(self,"d"..i,v)
			rawset(self,"direction",nil)
			rawset(self,"mag",nil)
		end
	end,
	__tostring = function(self)
		return "["..tostring(self.da).."], ["..tostring(self.db).."]"
	end
},{
	closest = function(self,v)
		local p = v-self.a
		local delta = max(0,p.unit:dot(self.direction))

		return self.a+self.direction*p.mag*delta
	end,
	circleIntersect = function(self,v,r)
		local p = self:closest(v)
		if (p-v).mag <= r then
			p = p-self.direction*sqrt(r^2-(p-self.a).mag^2)
			if (p-self.a).mag <= self.mag then
				return p
			end
		end
	end,
	lineIntersect = function(self,line)
		local a,b,c,d = self.a,self.b,line.a,line.b
		local r = b-a
		local s = d-c
		local d = r:cross(s)

		local u = (c-a):cross(r)/d
		local t = (c-a):cross(s)/d

		return 0 <= u and u <= 1 and 0 <= t and t <= 1 and a+t*r or nil
	end,
	rectIntersect = function(self,rect)
		local axis = rect:axis()
		local c = rect.corner
		local x,y = self.direction:cross(axis[2]),-self.direction:cross(axis[1])
		local h,v

		if x >= 0 then
			h = self:lineIntersect(Line:new(c[1],c[4]))
		else h = self:lineIntersect(Line:new(c[2],c[3]))
		end

		if y >= 0 then
			v = self:lineIntersect(Line:new(c[1],c[2]))
		else v = self:lineIntersect(Line:new(c[3],c[4]))
		end

		return h or v
	end,
	mapIntersect = function(self,map)
		local dir = self.direction
		local size = map.size
		local x,y = -Vector2:new(0,1):cross(dir),Vector2:new(1,0):cross(dir)
		local offset = Vector2:new(
			floor(self.a.x/size)-((self.a.x/size)%1 == 0 and x < 0 and 1 or 0),
			floor(self.a.y/size)-((self.a.y/size)%1 == 0 and y < 0 and 1 or 0)
		)
		local c = Rect:new(Vector2:new(-0.5,-0.5),Vector2:new(1,1)).corner
		local sx,sy = x < 0 and -1 or 1,y < 0 and -1 or 1
		local vhuge = Vector2:new(huge,huge)
		local h1,h2,v1,v2

		if x < 0 then
			h1,h2 = c[1],c[4]
		else h1,h2 = c[2],c[3]
		end
		if y < 0 then
			v1,v2 = c[1],c[2]
		else v1,v2 = c[3],c[4]
		end

		local function hit(pos,dis)
			local p = offset+Vector2:new(0.5,0.5)
			local lx = self:lineIntersect(Line:new(
				(p+h1)*size,
				(p+h2)*size
			)) or vhuge
			local ly = self:lineIntersect(Line:new(
				(p+v1)*size,
				(p+v2)*size
			)) or vhuge
			lx,ly = lx-pos,ly-pos

			local d = lx.mag < ly.mag
			local l = d and lx or ly

			if l.mag <= dis then
				if d then
					offset = offset+Vector2:new(sx,0)
				else offset = offset+Vector2:new(0,sy)
				end
				if offset.x >= 0 and offset.x < map.x and offset.y >= 0 and offset.y < map.y then
					local tile = map.tile[offset.x+map.x*offset.y]
					if tile and tile.collision then
						return tile,pos+l
					else return hit(pos+l,dis-l.mag)
					end
				end
			end

			return nil,pos+dir*dis
		end

		return hit(self.a,self.mag)
	end
},function(self,a,b)
	self.a = a or Vector2:new()
	self.b = b or Vector2:new()
end)