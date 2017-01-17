local class = {}

instance = {}
instance.__index = instance

function instance:class(name,t)
	if not class[name] then
		t = t or {}
		t.__index = t

		t.name = function()
			return name
		end
		t.is = function(t,name)
			return t:name() == name or self:is(name)
		end
		t.new = function(t)
			return setmetatable({},t)
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
		t = setmetatable(t,self)

		class[name] = t
		return t
	else print("Class '"..name.."' already exists!")
	end
end

function instance:new(name)
	if class[name] then
		return class[name]:new()
	else print("Class '"..name.."' does not exist!")
	end
end

function instance:name()
	return "instance"
end

function instance:is(name)
	return self:name() == name
end

function instance:update()
end

function instance:draw()
end