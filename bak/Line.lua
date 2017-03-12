local max,sqrt,floor,huge = math.max,math.sqrt,math.floor,math.huge

Line = Instance:api({
	new = function(self,a,b)
		self.a = a or Vector2:new()
		self.b = b or Vector2:new()
	end,
	__index = function(self,k,v)
		if i == "direction" then
			v = (self.b-self.a).unit
			self.direction = v
		elseif i == "mag" then
			v = (self.b-self.a).mag
			self.mag = v
		end

		return v
	end,
	__newindex = function(self,k,v)
		if (k == "a" or k == "b") and self[k] ~= v then
			self.direction = nil
			self.mag = nil
		end
	end,
	__tostring = function(self)
		return "["..tostring(self.a).."], ["..tostring(self.b).."]"
	end,
	closest = function(self,v)
		return lemon.line.closest(self.a,self.b,v)
	end,
	lineIntersect = function(self,line)
		return lemon.line.lineIntersect(self.a,self.b,line.a,line.b)
	end,
	circleIntersect = function(self,v,r)
		return lemon.line.circleIntersect(self.a,self.b,v,r)
	end,
	rectIntersect = function(self,rect)
		return lemon.line.rectIntersect(self.a,self.b,rect)
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
})
