local class = {}
lel = 0

--[[ security ]
1 - root
2 - service
3 - object
]]
instance = {}
instance.__index = instance

local function copy(t)
	local n = {}
	for k,v in pairs(t) do
		if type(v) == "table" then
			n[k] = copy(v)
		else n[k] = v
		end
	end

	return setmetatable(n,getmetatable(t))
end

function instance:class(name,security)
	if not class[name] then
		security = security or 3
		return function(t)
			t = t or {}
			t.__index = t

			t.name = function()
				return name
			end
			t.security = function()
				return security
			end
			t.is = function(t,name)
				return t:name() == name or self:is(name)
			end
			local constructor = t.constructor
			t.new = function(t,...)
				local n = setmetatable({},t)
				for k,v in pairs(t) do
					if v == instance.event then
						n[k] = v()
					elseif type(v) == "table" and k:sub(0,2) ~= "__" then
						n[k] = copy(v)
					end
				end
				if constructor then
					constructor(n,...)
				end
				return n
			end
			t.clone = function(t)
				local meta = getmetatable(t)
				setmetatable(t,{})
				local n = setmetatable({},meta)
				for k,v in pairs(t) do
					n[k] = v
				end
				setmetatable(t,meta)
				return n
			end
			local update = t.update or instance.update
			t.update = function(t,dt)
				self.update(t,dt)
				update(t,dt)
			end
			local draw = t.draw or instance.draw
			t.draw = function(t,...)
				self.draw(t,...)
				draw(t,...)
			end

			class[name] = setmetatable(t,self)

			return t
		end
	else print("Class '"..name.."' already exists!")
	end
end

--[[ event ]
Inherits: instance

Description: Allows the option to add 'hooks' and be fired all at once.

Functions:
	nil fire( - Fires all connected hooks.
		instance source, - The source of the event.
		... - Passed parameters.
	)
	hook connect( - Connects a hook to this event.
		function func - callback function to be executed everytime 'fire' is called.
	) - returns a hook object.
	nil disconnect( - disconnects a hook from this event.
		hook hook - hook object.
	)
]]
function instance:event()
	return {
		fire = function(self,...)
			if not self.hook then
				self.hook = {}
			end
			for k,v in pairs(self.hook) do
				if v then
					k:fire(...)
				else self.hook[k] = nil
				end
			end
		end,
		connect = function(self,func)
			if not self.hook then
				self.hook = {}
			end
			local v = instance:new("hook")
			v.event = self
			v.func = func
			self.hook[v] = true

			return v
		end,
		disconnect = function(self,hook)
			if not self.hook then
				self.hook = {}
			end
			if self.hook[hook] then
				self.hook[hook] = nil
			end
		end,
		disconnectAll = function(self)
			self.hook = {}
		end
	}
end

function instance:new(name,...)
	if name and class[name] then
		if class[name]:security() == 3 then
			return class[name]:new(...)
		else print("Unable to instantiate class '"..name.."'.","Security level is",class[name]:security()..".")
		end
	else print("Class '"..name.."' does not exist!")
	end
end

function instance:service(name)
	if class[name] and class[name]:security() == 2 then
		return class[name]
	end
end

function instance:name()
	return "instance"
end

function instance:is(name)
	return self:name() == name
end

function instance:security(name)
	return 1
end

function instance:update() end

function instance:draw() end