local class = {}
lel = 0

--[[ Security Level ]
1 - Root
	The highest authority of all classes. The only class with this security level is the 'Instance' class.

2 - Service
	These classes cannot be instantiated, and must use the class itself.
	You can reference these by using 'Instance:service(name)'.

3 - Object
	These classes must be instantiated into an object. The class is used as a default reference for all of its objects,
	and therefore will change all of them when the class is changed.
]]
Instance = {}
Instance.__index = Instance

local function copy(t)
	local n = {}
	for k,v in pairs(t) do
		if type(v) == "table" and v ~= t then
			n[k] = copy(v)
		else n[k] = v
		end
	end

	return setmetatable(n,getmetatable(t))
end

--[[ Instance ]
Description: Root class for all succeeding classes.

Functions:
	function class( - Creates a new class and inherits the preceding classes.
					  Calling this function on a descendant class will inherit that class as well.
		String name - The name of the class. Cannot override existing classes of the same name.
		Number security - Access level for instantiation.
	) Instance ( - Returns a callback function.
		Table t - Collection of properties for the class.
	) - Returns the class.

	Table event() - Creates an event handler for classes.
					Returns a table that can handle 'Hook' objects.

	Instance new( - Instantiates a class referencing the given class name.
		String name - Reference name.
		Function prop( - Properties for altering the object directly.
			Instance self - The object being altered.
		)
	) - Returns an instantiated class, or an object.

	Instance service( - Returns a class with a security level of 2.
		String name - The name of the class.
	) - Returns a security level 2 class, or a service class.

	String name() - Returns the name of the class.

	Boolean is( - Checks if the class has the same name, or is inheriting the given class.
		String name - Reference name.
	) - Returns true if the class or one of the classes it inherits has the same name.

	Integer security() - Returns the security level of the class.

	nil update() - Placeholder for the update function. It is encouraged to override this function when creating a new class.

	nil draw() - Placeholder for the draw function. It is encouraged to override this function when creating a new class.
]]
function Instance:class(name,security)
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
			local constructor = t.new
			t.new = function(t,prop)
				local n = self:name() ~= "Instance" and self:new() or {}
				n = setmetatable(n,t)
				for k,v in pairs(t) do
					if v == Instance.event then
						n[k] = v()
					elseif type(v) == "table" and v ~= t then
						n[k] = copy(v)
					end
				end
				if constructor then
					constructor(n)
				end
				if prop then
					prop(n)
				end
				return n
			end
			t.clone = function(t,prop)
				local meta = getmetatable(t)
				setmetatable(t,{})
				local n = setmetatable(copy(t),meta)
				setmetatable(t,meta)
				if prop then
					prop(n)
				end
				return n
			end
			local destroy = t.destroy or Instance.destroy
			t.destroy = function(t)
				self.destroy(t)
				destroy(t)
			end
			local update = t.update or Instance.update
			t.update = function(t,dt)
				self.update(t,dt)
				update(t,dt)
			end
			local draw = t.draw or Instance.draw
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

--[[ Event ]
Inherits: Instance

Description: Allows the option to add 'Hooks' and be fired all at once.

Functions:
	nil fire( - Fires all connected hooks.
		Instance source, - The source of the event.
		... - Passed parameters.
	)
	Hook connect( - Connects a hook to this event.
		function func - callback function to be executed everytime 'fire' is called.
	) - returns a hook object.
	nil disconnect( - disconnects a hook from this event.
		hook hook - hook object.
	)
]]
function Instance:event()
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
			local v = Instance:new("Hook")
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

function Instance:new(name,prop)
	if name and class[name] then
		if class[name]:security() == 3 then
			return class[name]:new(prop)
		else print("Unable to instantiate class '"..name.."'.","Security level is",class[name]:security()..".")
		end
	else print("Class '"..name.."' does not exist!")
	end
end

function Instance:service(name)
	if class[name] and class[name]:security() == 2 then
		return class[name]
	end
end

function Instance:name()
	return "Instance"
end

function Instance:is(name)
	return self:name() == name
end

function Instance:security()
	return 1
end

function Instance:destroy() end

function Instance:update() end

function Instance:draw() end