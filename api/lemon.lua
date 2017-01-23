local max,min = math.max,math.min

lemon = Instance:api({
	clamp = function(a,b,v)
		return max(a or 0,min(v or 0,b or 0))
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
	}
})