local sin,abs,random,max,min,floor,pi,asin = math.sin,math.abs,math.random,math.max,math.min,math.floor,math.pi,math.asin

local function beginContact(self,a,b,...)
	a = self.fixtureToRigid[a]
	b = self.fixtureToRigid[b]
	if a and b then
		a.beginContact:fire(b,...)
		b.beginContact:fire(a,...)
	end
end

local function endContact(self,a,b,...)
	a = self.fixtureToRigid[a]
	b = self.fixtureToRigid[b]
	if a and b then
		a.endContact:fire(b,...)
		b.endContact:fire(a,...)
	end
end

local function preSolve(self,a,b,...)
	a = self.fixtureToRigid[a]
	b = self.fixtureToRigid[b]
	if a and b then
		a.preSolve:fire(b,...)
		b.preSolve:fire(a,...)
	end
end

local function postSolve(self,a,b,...)
	a = self.fixtureToRigid[a]
	b = self.fixtureToRigid[b]
	if a and b then
		a.postSolve:fire(b,...)
		b.postSolve:fire(a,...)
	end
end

local Map = Instance:class("Map",3)({
	world = nil,
	queue = {},
	bodies = {},
	fixtureToRigid = {},
	new = function(self)
		self.world = love.physics.newWorld(0,0)
		self.world:setCallbacks(function(a,b,...)
			beginContact(self,a,b,...)
		end,function(a,b,...)
			endContact(self,a,b,...)
		end,function(a,b,...)
			preSolve(self,a,b,...)
		end,function(a,b,...)
			postSolve(self,a,b,...)
		end)
		--[[self.world:setContactFilter(function(a,b)
			local _,_,_,x,y = love.physics.getDistance(a,b)
			a,b = self.fixtureToRigid[a],self.fixtureToRigid[b]
			-- A = platform; B = Object

			if not a or not b then return end
			-- A or B prematurely destroyed.

			return a:is("Entity") or -- A is not a valid platform.
				not a.platform or -- A is not a platform.
				a.body:getY() >= b.body:getY() and not a.fixture:testPoint(x,y) -- Check if B is above and not inside A.
		end)]]
	end,
	add = function(self,rigid)
		self.bodies[rigid] = true
		self.fixtureToRigid[rigid.fixture] = rigid

		return rigid
	end,
	entityShape = function(self,x,y)
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
	rigid = function(self,body,shape,fixture,image)
		local rigid = Instance:new("Rigid")
		rigid:bake(self,body,shape,fixture,image)

		return self:add(rigid)
	end,
	entity = function(self,body,shape,fixture,image)
		local entity = Instance:new("Entity")
		body:setFixedRotation(true)
		fixture:setGroupIndex(-1)
		entity:bake(self,body,shape,fixture,image)

		local function check(hit,col)
			if not entity.ground[hit] then
				local _,y = col:getNormal()
				if pi/2-asin(-y) <= entity.slope then
					entity.ground[hit] = col
					entity.groundcount = entity.groundcount+1
				end
			end
		end

		entity.beginContact:connect(check)
		entity.endContact:connect(function(hit,col)
			if entity.ground[hit] then
				entity.ground[hit] = nil
				entity.groundcount = entity.groundcount-1
			end
		end)
		entity.preSolve:connect(function(hit,col)
			if not hit:is("Entity") and hit.platform then
				if entity.platform or not entity.ground[hit] then
					if entity.ground[hit] then
						entity.endContact:fire(hit,col)
					end
					col:setEnabled(false)
				end
			end
			if col:isEnabled() then
				check(hit,col)
			end
		end)

		return self:add(entity)
	end,
	chain = function(self,image,static,a,b,...)
		local l = {...}
		if #l%2 == 1 and #l < 4 then return end

		local body = love.physics.newBody(self.world,a,b,static and "static" or "dynamic")
		local shape

		if #l > 4 then
			shape = love.physics.newChainShape(false,l)
		else shape = love.physics.newEdgeShape(...)
		end

		local fixture = love.physics.newFixture(body,shape)

		return self:rigid(body,shape,fixture,image)
	end,
	circle = function(self,image,static,a,b,r)
		local body = love.physics.newBody(self.world,a,b,static and "static" or "dynamic")
		local shape = love.physics.newCircleShape(r)
		local fixture = love.physics.newFixture(body,shape)

		return self:rigid(body,shape,fixture,image)
	end,
	rectangle = function(self,image,static,a,b,c,d)
		local body = love.physics.newBody(self.world,a,b,static and "static" or "dynamic")
		local shape = love.physics.newRectangleShape(c,d)
		local fixture = love.physics.newFixture(body,shape)

		return self:rigid(body,shape,fixture,image)
	end,
	postUpdate = function(self,func)
		self.queue[func] = true
	end,
	draw = function(self,x,y,angle,...)
		love.graphics.push()
		love.graphics.rotate(angle)
		for v,_ in pairs(self.bodies) do
			v:draw(x,y,0,...)
		end
		love.graphics.pop()
	end,
	update = function(self,dt)
		self.world:update(dt)
		for v,_ in pairs(self.bodies) do
			v:update(dt)
		end
		for v,_ in pairs(self.queue) do
			v()
			self.queue[v] = nil
		end
	end,
	destroy = function(self)
		for v,_ in pairs(self.bodies) do
			v:destroy()
		end
		self.world:destroy()
	end
})

local Rigid = Instance:class("Rigid",3)({
	world = nil,
	body = nil,
	shape = nil,
	fixture = nil,
	image = nil,
	imageOffset = Vector2:new(),
	imageScale = Vector2:new(1,1),
	drawpoints = true,
	lifespan = nil,
	platform = false,
	bake = function(self,world,body,shape,fixture,image)
		self.world = world
		self.body = body
		self.shape = shape
		self.fixture = fixture
		self.image = image
	end,
	box = function(self)
		local a,b,c,d = self.shape:computeAABB(self.body:getX(),self.body:getY(),0)

		return a,b,floor(c-a),floor(d-b)
	end,
	draw = function(self,x,y,angle,sx,sy,...)
		local rot = self.body:getAngle()+angle
		local a,b,c,d = self:box()
		local ox,oy = self.imageOffset:components()
		local ix,iy = self.imageScale:components()
		love.graphics.push()
		love.graphics.translate(x,y)
		love.graphics.scale(sx,sy)

		if self.image then
			self.image:draw(a+ox,b+oy,rot,ix,iy,...)
		end

		if self.drawpoints then
			local v = self.shape:type()
			local x,y = self.body:getX(),self.body:getY()

			-- Shape
			love.graphics.setColor(255,127,127)
			if v == "PolygonShape" then
				love.graphics.polygon("line",self.body:getWorldPoints(self.shape:getPoints()))
			elseif v == "CircleShape" then
				local x,y = self.body:getWorldPoints(self.shape:getPoint())
				love.graphics.ellipse("line",x,y,self.shape:getRadius())
			elseif v == "ChainShape" or v == "EdgeShape" then
				love.graphics.line(self.body:getWorldPoints(self.shape:getPoints()))
			end

			-- Shape Offset
			love.graphics.setColor(127,255,127)
			love.graphics.line(x,y,a+c/2,b+d/2)
			love.graphics.ellipse("fill",x,y,2)
			love.graphics.ellipse("fill",a+c/2,b+d/2,2)

			-- Bounding Box
			love.graphics.push()
			love.graphics.setColor(127,127,255)
			love.graphics.rotate(rot)
			local p = Vector2:new(a,b):rotateToVectorSpace(-Vector2:new(c,d)/2,-rot)
			love.graphics.rectangle("line",p.x,p.y,c,d)
			love.graphics.pop()
		end

		love.graphics.pop()
	end,
	update = function(self,dt)
		if self.lifespan ~= nil and self.lifespan <= 0 then
			self:destroy()
		else if self.lifespan then
				self.lifespan = self.lifespan-dt
			end
			if self.image then
				self.image:update(dt)
			end
			self.postUpdate:fire(dt)
		end
	end,
	destroy = function(self)
		for _,c in pairs(self.body:getContactList()) do
			local a,b = c:getFixtures()
			endContact(self.world,a,b,c)
			postSolve(self.world,a,b,c)
		end
		self.world.fixtureToRigid[self.fixture] = nil
		self.world.bodies[self] = nil
		self.fixture:destroy()
		self.body:destroy()
	end,
	postUpdate = Instance.event,
	beginContact = Instance.event,
	endContact = Instance.event,
	preSolve = Instance.event,
	postSolve = Instance.event
})

local Entity = Rigid:class("Entity",3)({
	motion = 0,
	slope = pi/2-pi/6,
	ground = {},
	groundcount = 0,
	state = "idle",
	run = false,
	runMultiplier = 2,
	animation = {
		idle = {},
		walk = {},
		run = {},
		shift = {},
		jump = {},
		fall = {}
	},
	isGrounded = function(self)
		return self.groundcount > 0
	end,
	act = function(self,state)
		if self.state ~= state then
			self.state = state
			self.image.loop = state ~= "shift"
			local list = self.animation[state]
			if #list > 0 then
				local n = random(#list)
				self.image.startFrame = list[n][2]
				self.image.endFrame = list[n][3]
				self.image.delay = list[n][4]
				self.image.bounce = list[n][5]
				self.image:seek(list[n][2],list[n][1])
				self.image:play()
			end
		end
	end,
	animate = function(self)
		local m,g,r,img = self.motion,self:isGrounded(),self.run,self.image
		local x,y = self.body:getLinearVelocity()
		if g then
			if abs(x) > 0.1 then
				if m == 0 then
					self:act(r and "shift" or "idle") -- Stopping
				elseif m/abs(m) ~= x/abs(x) then
					self:act("shift") -- Shifting
				else self:act(r and "run" or "walk") -- Moving
					img.flip = m < 0
				end
			elseif m == 0 then
				self:act("idle") -- Standing
			else self:act(r and "run" or "walk") -- Moving
				img.flip = m < 0
			end
		elseif y < 0 then
			self:act("jump") -- Jumping
		else self:act("fall") -- Freefalling
		end
	end,
	update = function(self,dt)
		local m = self.motion
		if self.run then
			m = m*self.runMultiplier
		end
		if m ~= 0 then
			local v = m*love.physics:getMeter()
			local x = self.body:getLinearVelocity()

			if self:isGrounded() then
				if m < 0 then
					v = min(0,v-x)/dt
				else v = max(0,v-x)/dt
				end
			end
			self.body:applyForce(v,0)
		end
		self:animate()
	end
})