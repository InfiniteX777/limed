local max,min,sqrt,ceil,pi,cos,sin = math.max,math.min,math.sqrt,math.ceil,math.pi,math.cos,math.sin
local insert = table.insert

lemon = Instance:api({
	least = 5.421011185545e-20,
	clamp = function(a,b,v)
		return max(a or 0,min(v or 0,b or 0))
	end,
	lerp = function(a,b,d)
		d = max(-1,min(1,d))
		return a*(1-d)+b*d
	end,
	table = {
		init = function(t,...)
			for _,v in pairs({...}) do
				if not t[v] then
					t[v] = {}
				end
				t = t[v]
			end

			return t
		end,
		copy = function(t,to,meta)
			local n = to or {}
			for k,v in pairs(t) do
				if type(v) == "table" and v ~= t then
					n[k] = lemon.table.copy(v,nil,meta)
				else n[k] = v
				end
			end

			return meta and setmetatable(n,getmetatable(t)) or n
		end,
		merge = function(a,b,overwrite)
			for k,v in pairs(b) do
				if a[k] then
					if type(v) == "table" then
						if type(a[k]) == "table" then
							a[k] = lemon.table.merge(a[k],v,overwrite)
						elseif overwrite then
							a[k] = v
						end
					elseif type(v) == "function" then
						if overwrite then
							a[k] = v
						elseif type(a[k]) == "function" then
							local f = a[k]
							a[k] = function(...)
								f(...)
								v(...)
							end
						end
					elseif overwrite then
						a[k] = v
					end
				else a[k] = v
				end
			end

			return a
		end
	},
	line = {
		closest = function(a,b,c)
			local dir = (b-a).unit
			local p = c-a
			local delta = max(0,p.unit:dot(dir))

			return a+dir*p.mag*delta
		end,
		lineIntersect = function(a,b,c,d)
			local r = b-a
			local s = d-c
			local d = r:cross(s)

			local u = (c-a):cross(r)/d
			local t = (c-a):cross(s)/d

			return 0 <= u and u <= 1 and 0 <= t and t <= 1 and a+t*r or nil
		end,
		circleIntersect = function(a,b,c,r)
			local dis = (b-a).mag
			local dir = (b-a).unit
			local p = lemon.line.closest(a,b,c)
			if (p-c).mag <= r then
				p = p-dir*sqrt(r^2-(p-a).mag^2)
				if (p-a).mag <= dis then
					return p
				end
			end
		end,
		rectIntersect = function(a,b,rect)
			local dir = (b-a).unit
			local axis = rect:axis()
			local c = rect.corner
			local x,y = -dir:cross(axis[2]),dir:cross(axis[1])
			local h,v

			if x < 0 then
				h = lemon.line.lineIntersect(a,b,c[1],c[4])
			else h = lemon.line.lineIntersect(a,b,c[2],c[3])
			end

			if y < 0 then
				v = lemon.line.lineIntersect(a,b,c[1],c[2])
			else v = lemon.line.lineIntersect(a,b,c[3],c[4])
			end

			return h or v
		end
	},
	ellipse = {
		toPoly = function(a,b,d)
			local d = d or 16
			local l = {{}}

			if d <= 8 then
				for x=0,d-1 do
					insert(
						l[1],
						cos(x/d*pi*2)*a
					)
					insert(
						l[1],
						sin(x/d*pi*2)*b
					)
				end
			else local x = 1
				local i = 1
				while x <= d do
					x = x-1
					l[i] = {0,0}
					for n=0,min(7,d-x+1)-1 do
						insert(
							l[i],
							cos(x/d*pi*2)*a
						)
						insert(
							l[i],
							sin(x/d*pi*2)*b
						)
						x = x+1
					end
					i = i+1
				end
			end

			return l
		end,
		toLine = function(a,b,d)
			local d = d or 16
			local l = {}

			for x=0,d-1 do
				insert(l,
					cos(x/d*pi*2)*a
				)
				insert(l,
					sin(x/d*pi*2)*b
				)
			end

			return l
		end
	}
})
