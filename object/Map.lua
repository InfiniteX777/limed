local max = math.max

local function callback(self,name,a,b,col,...)
	local c = self.bodyToRigid[a:getBody()]
	local d = self.bodyToRigid[b:getBody()]
	if c and c:is("Projectile") then
		col:setEnabled(false)
	end
	if d and d:is("Projectile") then
		col:setEnabled(false)
	end
	if c and d then
		c[name]:fire(d,b,col,...)
		d[name]:fire(c,a,col,...)
	end
end

local superclass = {"Rigid","UI","Dialog"}
local Map = Instance:class("Map",4){
	world = nil,
	speed = 1,
	layer = {},
	objects = {},
	bodyToRigid = {},
	debounce = {},
	drawPoints = false,
	new = function(self,super)
		self.world = love.physics.newWorld(0,0)
		self.world:setCallbacks(function(a,b,...)
			callback(self,"beginContact",a,b,...)
		end,function(a,b,...)
			callback(self,"endContact",a,b,...)
		end,function(a,b,...)
			callback(self,"preSolve",a,b,...)
		end,function(a,b,...)
			callback(self,"postSolve",a,b,...)
		end)
	end,
	add = function(self,super,object,layer)
		local layer = layer or 0

		if layer < 0 then return end

		self.objects[object] = layer

		if object:is("Rigid") then
			self.bodyToRigid[object.body] = object
		end

		for _,v in pairs(superclass) do
			if object:is(v) then
				lemon.table.init(self.layer,layer,v)[object] = true
				break
			end
		end

		return object
	end,
	rem = function(self,super,object)
		if object:is("Rigid") and object.body then
			for _,c in pairs(object.body:getContactList()) do
				local a,b = c:getFixtures()
				callback(self,"endContact",a,b,c)
			end

			self.bodyToRigid[object.body] = nil
		end

		for _,v in pairs(superclass) do
			if object:is(v) then
				self.layer[self.objects[object]][v][object] = nil
				break
			end
		end
		self.objects[object] = nil
	end,
	indentLayer = function(self,super,layer)
		if layer < 0 then return end
		local t = {}
		for k,v in pairs(self.layer) do
			if k < layer then
				t[k] = v
			elseif k == layer then
				t[k] = {}
			else t[k+1] = v
			end
		end

		self.layer = t
	end,
	setBackground = function(self,super,layer,image,x,y)
		local t = lemon.table.init(self.layer,layer,"background")
		t.image = image
		t.x = x
		t.y = y
	end,
	rigid = function(self,super,layer,body,image)
		local rigid = Instance:new("Rigid")
		rigid.map = self
		rigid.body = body
		rigid.image = image

		return self:add(rigid,layer)
	end,
	projectile = function(self,super,layer,body,image,source)
		local projectile = Instance:new("Projectile")
		projectile.map = self
		projectile.body = body
		projectile.image = image
		projectile.source = source

		body:setFixedRotation(true)
		body:setBullet(true)

		return self:add(projectile,layer)
	end,
	entity = function(self,super,layer,body,image)
		local entity = Instance:new("Entity")
		entity.map = self
		entity.body = body
		entity.image = image

		-- Setup for Common Entity Properties
		body:setFixedRotation(true)
		body:setBullet(true)
		body:setMass(1)
		entity:applyFixture(function(v)
			v:setGroupIndex(-1)
			v:setFriction(0.8)
		end)

		return self:add(entity,layer)
	end,
	polyline = function(self,super,static,a,b,...)
		local l = {...}
		if type(l[1]) == "table" then
			l = l[1]
		end
		if #l%2 == 1 or #l < 4 then return end

		local body = love.physics.newBody(self.world,a,b,static and "static" or "dynamic")

		if #l > 4 then
			love.physics.newFixture(body,love.physics.newChainShape(false,l))
		else love.physics.newFixture(body,love.physics.newEdgeShape(unpack(l)))
		end

		return body
	end,
	polygon = function(self,super,static,a,b,...)
		local l = {...}
		if type(l[1]) == "table" then
			l = l[1]
		end
		if #l%2 == 1 or #l < 6 then return end

		local body = love.physics.newBody(self.world,a,b,static and "static" or "dynamic")
		local shape = love.physics.newPolygonShape(l)

		local fixture = love.physics.newFixture(body,shape)

		return body
	end,
	ellipse = function(self,super,static,a,b,c,d,s)
		local body = love.physics.newBody(self.world,a,b,static and "static" or "dynamic")

		local d = d or c
		if c == d and not s then
			love.physics.newFixture(body,love.physics.newCircleShape(c))
		else for k,v in pairs(lemon.ellipse.toPoly(c,d,s)) do
				love.physics.newFixture(body,love.physics.newPolygonShape(v))
			end
		end

		return body
	end,
	rectangle = function(self,super,static,a,b,c,d)
		local body = love.physics.newBody(self.world,a,b,static and "static" or "dynamic")
		love.physics.newFixture(body,love.physics.newRectangleShape(c,d))

		return body
	end,
	postUpdate = function(self,super,...)
		for _,v in pairs({...}) do
			self.queue[v] = true
		end
	end,
	draw = function(self,super,x,y,angle,...)
		love.graphics.push()
		love.graphics.rotate(angle)
		for _,layer in pairs(self.layer) do
			for _,class in pairs(superclass) do
				if layer[class] then
					for v,_ in pairs(layer[class]) do
						v:draw(x,y,0,...)
					end
				end
			end
		end
		love.graphics.pop()
	end,
	update = function(self,super,dt)
		dt = dt*self.speed
		self.world:update(dt)
		for _,layer in pairs(self.layer) do
			for _,class in pairs(superclass) do
				if layer[class] then
					for v,_ in pairs(layer[class]) do
						v:update(dt)
						if v.image then
							self.debounce[v.image] = true
						end
					end
				end
			end
		end
		self.debounce = {}
	end,
	destroy = function(self,super)
		for v,_ in pairs(self.objects) do
			v:destroy()
		end
		self.world:destroy()
		super.destroy(self)
	end
}
