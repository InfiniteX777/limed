local insert = table.insert

local module = {
	"api",
	"reference",
	"object",
	"service"
}

local path = (...) and (...):gsub("%.init$",""):gsub("%.","/") or ""

local class = {}
local queue = {}

Instance = {}
Instance.__index = Instance

function Instance:class(name,security)
	if not class[name] then
		local security = security or 3
		return function(t)
			local t = t or {}
			t.__index = t

			for k,v in pairs(t) do
				if type(v) == "function" then
					local f = v
					t[k] = function(child,...)
						return f(child,self,...)
					end
				end
			end

			t.name = function()
				return name
			end

			t.security = function()
				return security
			end

			t.is = function(t,ref,recursive)
				if recursive == nil then
					recursive = true
				end
				return name == ref or recursive and self:is(ref)
			end

			t.constructor = t.new

			t.new = nil

			class[name] = setmetatable(t,self)

			if queue[k] then
				for _,v in pairs(queue[k]) do v() end
				queue[k] = nil
			end

			return t
		end
	else print("Class '"..name.."' already exists!")
	end
end

function Instance:api(meta,func,const)
	if const then
		function meta:new(...)
			local t = setmetatable(func and lemon.table.copy(func) or {},meta)
			const(t,...)

			return t
		end
	end

	return meta
end

local event = {
	fire = function(self,...)
		for k,v in pairs(self.hook) do
			if v then
				k:fire(...)
			else self.hook[k] = nil
			end
		end
	end,
	connect = function(self,callback)
		local v = Instance:new("Hook")
		v.event = self
		v.callback = callback
		self.hook[v] = true

		return v
	end,
	disconnect = function(self,hook)
		if self.hook[hook] then
			self.hook[hook] = nil
		end
	end,
	disconnectAll = function(self)
		self.hook = {}
	end
}
function Instance:event()
	return {
		hook = {},
		fire = event.fire,
		connect = event.connect,
		disconnect = event.disconnect,
		disconnectAll = event.disconnectAll,
		__event = true
	}
end

function Instance:new(name,prop)
	if name and class[name] then
		local security = class[name]:security()
		local superName = self:name()
		if security == 3 then -- Creating object classes with root class.
			return class[name]:construct(prop)
		elseif security == 4 and self:security() == 2 then -- Creating reference classes with service classes.
			return class[name]:construct(prop)
		elseif class[name]:is(superName) and name ~= superName then -- Creating descendant classes with ancestral classes.
			return class[name]:construct(function(n)
				lemon.table.copy(self,n)
				if prop then
					prop(n)
				end
			end)
		else print("Unable to instantiate class '"..name.."' with class '"..superName.."'. Security level is "..class[name]:security()..".")
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

function Instance:security()
	return 1
end

--[[function Instance:is(name)
	return self:name() == name or self.super and self.super:is(name) or false
end]]

function Instance:is(name)
	return self:name() == name
end

function Instance:clone(prop)
	return self:construct(function(t)
		lemon.table.copy(self,t,true)
		if prop then
			prop(n)
		end
	end)
end

function Instance:destroy()
	for k,v in pairs(self) do
		if type(v) == "table" and v.__event then
			v:disconnectAll()
		end
		self[k] = nil
	end
end

function Instance:update() end

function Instance:draw() end

function Instance:constructor() end

function Instance:construct(prop,sys)
	local t = setmetatable({},self)
	local meta = self
	while meta ~= nil do
		for k,v in pairs(meta) do
			if type(v) == "table" and v ~= t and k ~= "super" then
				t[k] = lemon.table.copy(v,nil,true)
			end
		end
		meta = getmetatable(meta)
	end

	self.constructor(t)

	if prop then
		prop(t)
	end

	return t
end

function Instance:waitFor(name,callback)
	if class[name] then
		callback()
	else if not queue[name] then
			queue[name] = {}
		end
		insert(queue[name],callback)
	end
end

for _,t in pairs(module) do
	for _,v in pairs(love.filesystem.getDirectoryItems(path.."/"..t)) do
		require(path.."."..t.."."..v:gsub("%.lua$",""))
	end
end