local max = math.max

local Map = Instance:class("Map",4)({
	world = nil,
	layer = {},
	queue = {},
	bodies = {},
	bodyToRigid = {},
	debounce = {},
	new = function(self,super)
		self.world = love.physics.newWorld(0,0)
		self.world:setCallbacks(function(a,b,...)
			self:callback("beginContact",a,b,...)
		end,function(a,b,...)
			self:callback("endContact",a,b,...)
		end,function(a,b,...)
			self:callback("preSolve",a,b,...)
		end,function(a,b,...)
			self:callback("postSolve",a,b,...)
		end)
	end,
	callback = function(self,super,callback,a,b,...)
		local c = self.bodyToRigid[a:getBody()]
		local d = self.bodyToRigid[b:getBody()]
		if c and d then
			c[callback]:fire(d,b,...)
			d[callback]:fire(c,a,...)
		end
	end,
	add = function(self,super,rigid,layer)
		self.bodies[rigid] = layer
		self.bodyToRigid[rigid.body] = rigid

		lemon.table.init(self.layer,layer)[rigid] = true

		return rigid
	end,
	setBackground = function(self,super,layer,image,x,y)
		local t = lemon.table.init(self.layer,layer,"background")
		t.image = image
		t.x = x
		t.y = y
	end,
	entityShape = function(self,super,x,y)
		local r = max(0,y-x)/2

		return love.physics.newPolygonShape(
			-x/2,-r,
			0,-y/2,
			x/2,-r,
			x/2,r,
			0,y/2,
			-x/2,r
		)
	end,
	rigid = function(self,super,layer,body,image)
		local rigid = Instance:new("Rigid")
		rigid.world = self
		rigid.body = body
		rigid.image = image

		return self:add(rigid,layer)
	end,
	projectile = function(self,super,layer,body,image,source)
		local projectile = Instance:new("Projectile")
		projectile.world = self
		projectile.body = body
		projectile.image = image
		projectile.source = source

		body:setFixedRotation(true)
		body:setBullet(true)

		return self:add(projectile,layer)
	end,
	entity = function(self,super,layer,body,image)
		local entity = Instance:new("Entity")
		entity.world = self
		entity.body = body
		entity.image = image

		-- Setup for Common Entity Properties
		body:setFixedRotation(true)
		body:setMass(1)
		for k,v in pairs(body:getFixtureList()) do
			v:setGroupIndex(-1)
			v:setFriction(1)
		end

		return self:add(entity,layer)
	end,
	polyline = function(self,super,layer,image,static,a,b,...)
		local l = {...}
		if type(l[1]) == "table" then
			l = l[1]
		end
		if #l%2 == 1 or #l < 4 then return end

		local body = love.physics.newBody(self.world,a,b,static and "static" or "dynamic")
		local shape

		if #l > 4 then
			shape = love.physics.newChainShape(false,l)
		else shape = love.physics.newEdgeShape(unpack(l))
		end

		local fixture = love.physics.newFixture(body,shape)

		return self:rigid(layer,body,image),fixture
	end,
	polygon = function(self,super,layer,image,static,a,b,...)
		local l = {...}
		if type(l[1]) == "table" then
			l = l[1]
		end
		if #l%2 == 1 or #l < 6 then return end

		local body = love.physics.newBody(self.world,a,b,static and "static" or "dynamic")
		local shape = love.physics.newPolygonShape(l)

		local fixture = love.physics.newFixture(body,shape)

		return self:rigid(layer,body,image),fixture
	end,
	ellipse = function(self,super,layer,image,static,a,b,c,d,s)
		local body = love.physics.newBody(self.world,a,b,static and "static" or "dynamic")

		local d = d or c
		if c == d and not s then
			love.physics.newFixture(body,love.physics.newCircleShape(c))
		else local ellipse = lemon.ellipse.toPoly(c,d,s)
			for k,v in pairs(ellipse) do
				love.physics.newFixture(body,love.physics.newPolygonShape(v))
			end
		end

		return self:rigid(layer,body,image),unpack(body:getFixtureList())
	end,
	rectangle = function(self,super,layer,image,static,a,b,c,d)
		local body = love.physics.newBody(self.world,a,b,static and "static" or "dynamic")
		local shape = love.physics.newRectangleShape(c,d)
		local fixture = love.physics.newFixture(body,shape)

		return self:rigid(layer,body,image),fixture
	end,
	postUpdate = function(self,super,...)
		for _,v in pairs({...}) do
			self.queue[v] = true
		end
	end,
	draw = function(self,super,x,y,angle,...)
		love.graphics.push()
		love.graphics.rotate(angle)
		for _,v in pairs(self.layer) do
			for v,_ in pairs(v) do
				v:draw(x,y,0,...)
			end
		end
		love.graphics.pop()
	end,
	update = function(self,super,dt)
		self.world:update(dt)
		for _,layer in pairs(self.layer) do
			for v,_ in pairs(layer) do
				v:update(dt)
				if v.image then
					self.debounce[v.image] = true
				end
			end
		end
		for v,_ in pairs(self.queue) do
			v()
			self.queue[v] = nil
		end
		self.debounce = {}
	end,
	destroy = function(self,super)
		for v,_ in pairs(self.bodies) do
			v:destroy()
		end
		self.world:destroy()
		super.destroy(self)
	end
})