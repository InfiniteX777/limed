local pi,asin,abs,min,max,random,cos,sin,floor = math.pi,math.asin,math.abs,math.min,math.max,math.random,math.cos,math.sin,math.floor
local graphics = Instance:service"GraphicsInterface"
local content = Instance:service"ContentService"

local Rigid = Instance:class("Rigid",3){
	map = nil,
	body = nil,
	image = nil,
	imageOffset = Vector2:new(),
	imageScale = Vector2:new(1,1),
	lifespan = nil,
	platform = false,
	bouncy = false,
	drawPoints = false,
	applyFixture = function(self,super,callback)
		for _,v in pairs(self.body:getFixtureList()) do
			callback(v)
		end
	end,
	getLayer = function(self,super)
		return self.map and self.map.objects[self] or nil
	end,
	draw = function(self,super,x,y,angle,sx,sy,...)
		local rot = self.body:getAngle()+angle
		local bx,by = self.body:getPosition()
		love.graphics.push()
		love.graphics.translate(x,y)
		love.graphics.scale(sx,sy)

		if self.image then
			local ox,oy = self.imageOffset:components()
			local ix,iy = self.imageScale:components()
			local mx,my = self.image.width,self.image.height
			self.image:draw(bx-mx/2*ix+ox,by-my/2*iy+oy,rot,ix,iy,...)
		end

		if self.drawPoints or self.map and self.map.drawPoints then
			for _,v in pairs(self.body:getFixtureList()) do
				local shape = v:getShape()
				local type = shape:type()
				graphics:pushColor(
					self.body:getMass() > 0 and 63 or 255,
					v:isSensor() and 63 or 255,
					self.platform and 63 or 255
				)
				if type == "PolygonShape" then
					love.graphics.polygon("line",self.body:getWorldPoints(shape:getPoints()))
					graphics:pushColor(255,255,255,31)
					love.graphics.polygon("fill",self.body:getWorldPoints(shape:getPoints()))
					graphics:popColor()
				elseif type == "CircleShape" then
					local x,y = self.body:getWorldPoints(shape:getPoint())
					love.graphics.ellipse("line",x,y,shape:getRadius())
					graphics:pushColor(255,255,255,31)
					love.graphics.ellipse("fill",x,y,shape:getRadius())
					graphics:popColor()
				elseif type == "ChainShape" or type == "EdgeShape" then
					love.graphics.line(self.body:getWorldPoints(shape:getPoints()))
				end
				graphics:popColor()
			end

			love.graphics.ellipse("fill",bx,by,2)
		end

		love.graphics.pop()
	end,
	update = function(self,super,dt)
		if self.lifespan ~= nil and self.lifespan <= 0 then
			self:destroy()
		else if self.lifespan then
				self.lifespan = self.lifespan-dt
			end
			if self.image and not self.map.debounce[self.image] then
				self.image:update(dt)
			end
		end
	end,
	destroy = function(self,super)
		if self.map then
			self.map:rem(self)
		end
		if self.body then
			self:applyFixture(function(v)
				v:setSensor(true)
			end)

			self.body:destroy()
		end
		super.destroy(self)
	end,
	beginContact = Instance:event(),
	endContact = Instance:event(),
	preSolve = Instance:event(),
	postSolve = Instance:event()
}

local Projectile = Rigid:class("Projectile",3){
	thrust = Vector2:new(),
	force = Vector2:new(),
	fixedAngle = nil,
	interceptProjectiles = false,
	source = nil,
	list = {},
	whitelist = false,
	new = function(self,super)
		self.beginContact:connect(function(hit,fixture,col)
			if fixture:isSensor() then return end
			-- Sensor hit.

			if hit:is("Projectile") and hit.source == self.source then return end
			-- Same source hit.

			if not hit:is("Entity") and hit.platform then return end
			-- Platform hit.

			if not self.interceptProjectiles and hit:is("Projectile") then return end
			-- Projectile hit.

			if self.whitelist and not self.list[hit] then return end
			-- Non-whitelist hit.

			if not self.whitelist and self.list[hit] then return end
			-- Blacklist hit.

			self.projectileHit:fire(hit,fixture,col)
		end)
	end,
	update = function(self,super,dt)
		if self.body then
			if not self.fixedAngle then
				local x,y = self.body:getLinearVelocity()
				self.body:setAngle(math.atan2(y,x))
			else self.body:setAngle(self.fixedAngle)
			end
			local angle = self.body:getAngle()
			local c,s = cos(angle),sin(angle)
			local x = c*self.thrust.x+s*self.thrust.y+self.force.x
			local y = s*self.thrust.x+s*self.thrust.y+self.force.y
			self.body:applyForce(x,y)
		end
		super.update(self,dt)
	end,
	projectileHit = Instance:event()
}

local Entity = Rigid:class("Entity",3){
	motion = 0,
	momentum = 0,
	acceleration = 0.4,
	slope = pi/2-pi/6,
	ground = {},
	groundcount = 0,
	state = "idle",
	run = false,
	runMultiplier = 2.5,
	invulnearable = false,
	health = 100,
	maxHealth = 100,
	animation = {
		idle = {},
		walk = {},
		run = {},
		shift = {},
		jump = {},
		fall = {}
	},
	chatList = {},
	new = function(self,super)
		local function check(hit,fixture,col)
			if hit:is("Rigid",false) and not self.ground[col] and col:isEnabled() then
				local _,y = col:getNormal()
				if pi/2-asin(-y) <= self.slope then
					col:resetFriction()
					self.ground[col] = hit
					self.groundcount = self.groundcount+1
				else col:setFriction(0)
				end
				if not hit.bouncy then
					col:setRestitution(0)
				end
			end
		end

		self.beginContact:connect(check)
		self.endContact:connect(function(hit,fixture,col)
			if self.ground[col] then
				self.ground[col] = nil
				self.groundcount = self.groundcount-1
			end
		end)
		self.preSolve:connect(function(hit,fixture,col)
			if hit:is("Rigid",false) and hit.platform then
				if self.platform or not self.ground[col] then
					if self.ground[col] then
						self.endContact:fire(hit,fixture,col)
					end
					col:setEnabled(false)
				end
			end
			check(hit,fixture,col)
		end)
	end,
	isGrounded = function(self,super)
		return self.groundcount > 0
	end,
	act = function(self,super,state)
		local img = self.image
		if self.state ~= state and img then
			self.state = state
			img.loop = state ~= "shift"
			local list = self.animation[state]
			if #list > 0 then
				local n = random(#list)
				img.startFrame = list[n][2]
				img.endFrame = list[n][3]
				img.delay = list[n][4]
				img.bounce = list[n][5]
				img.speed = 1
				img:seek(list[n][2],list[n][1])
				img:play()
			end
		end
	end,
	animate = function(self,super)
		local m,mm,g,r,img = self.motion,abs(self.momentum),self:isGrounded(),self.run,self.image
		local x,y = self.body:getLinearVelocity()

		if not img then return end

		if self.run then
			mm = mm/self.runMultiplier
		end

		if g then
			if abs(x) > 0.01 then
				if m == 0 then
					self:act(r and "shift" or "idle") -- Stopping
				elseif m/abs(m) ~= x/abs(x) then
					self:act("shift") -- Shifting
				else self:act(r and "run" or "walk") -- Moving
					img.speed = mm/2
				end
			elseif m == 0 then
				self:act("idle") -- Standing
			else self:act(r and "run" or "walk") -- Moving
				img.speed = mm/2
			end
		elseif y < 0 then
			self:act("jump") -- Jumping
		else self:act("fall") -- Freefalling
		end

		img.flip = m == 0 and img.flip or m < 0
	end,
	chat = function(self,super,text,lifespan)
		local layer = self:getLayer()

		if text then
			self.map:add(Instance:new("Dialog",function(vself)
				vself.map = self.map
				vself.ui = Instance:new("BorderedFrame",function(self)
					self.fillColor.a = 0
					self.lineColor.a = 0
					self.borderImage = content:loadImage("assets/ui/dialog.png")
					self.borderEdgeSize = 10

					local label = Instance:new("Label",function(self)
						self.fillColor.a = 0
						self.lineColor.a = 0
						self.textWrap = true

						self.offset:set(10,10,-20,-20)
						self.scale:set(0,0,1,1)
						self:setText(text,256)
					end)
					self:add(label)

					local font = label.font.font
					local height = font:getHeight()
					local border = 20
					local width,list = font:getWrap(label.text.abs,300-border)

					self.offset:set(0,0,width+border,#list*height+border)

					vself.lifespan = (lifespan or 5)+label.text.abs:len()/256
				end)
				vself.rigid = self
			end),self:getLayer())
		end
	end,
	update = function(self,super,dt)
		local m = self.motion*(self.run and self.runMultiplier or 1)

		self.momentum = lemon.lerp(self.momentum,m,self.acceleration/2)

		if m ~= 0 then
			m = self.momentum
			local meter = love.physics:getMeter()
			local a = self.acceleration
			local v = self.momentum*meter
			local x = self.body:getLinearVelocity()

			v = m < 0 and max(min(0,v-x),v) or min(max(0,v-x),v)

			if not self:isGrounded() then
				v = v/meter/a*2
			end

			self.body:applyLinearImpulse(v*a,0)
		end
		self:animate()
		super.update(self,dt)
	end
}
