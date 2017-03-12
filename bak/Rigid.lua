local max,min,abs,atan2,floor,random = math.max,math.min,math.abs,math.atan2,math.floor,math.random

local Rigid = Instance:class("Rigid",3)({
	image = nil,
	hitbox = Vector2:new(),
	position = Vector2:new(),
	velocity = Vector2:new(),
	rotation = 0,
	drag = 0.1,
	weight = 1,
	map = nil,
	push = function(self,v)
		self.velocity = self.velocity+v
	end,
	rect = function(self)
		return Rect:new(
			self.position-self.hitbox/2,
			self.hitbox
		)
	end
})

local Entity = Rigid:class("Entity",3)({
	motion = 0,
	state = "idle",
	ground = nil,
	run = true,
	animation = {
		idle = {},
		walk = {},
		run = {},
		shift = {},
		jump = {},
		fall = {}
	},
	rect = function(self)
		return Rect:new(
			self.position-Vector2:new(self.hitbox.x/2,self.hitbox.y),
			self.hitbox
		)
	end,
	to = function(self,state)
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
		if self.ground then
			if abs(self.velocity.x) > 0.1 then
				if self.motion == 0 then
					self:to(self.run and "shift" or "idle") -- Stopping
				elseif self.motion/abs(self.motion) ~= self.velocity.x/abs(self.velocity.x) then
					self:to("shift") -- Shifting
				else self:to(self.run and "run" or "walk") -- Moving
					self.image.flip = self.motion < 0
				end
			elseif self.motion == 0 then
				self:to("idle") -- Standing
			else self:to(self.run and "run" or "walk") -- Moving
				self.image.flip = self.motion < 0
			end
		elseif self.velocity.y < 0 then
			self:to("jump") -- Jumping
		else self:to("fall") -- Freefalling
		end
	end,
	update = function(self,dt)
		local p = self.position-Vector2:new(0,self.hitbox.y/2)
		local g = self.map and self.map.gravity or Vector2:new()
		local x = (self.velocity.x-g.x)*self.drag*dt
		local y = -g.y*self.weight*dt

		-- movement

		if self.motion > 0 and self.velocity.x < self.motion then
			x = x-max(0,self.motion*dt-self.velocity.x)*self.drag
		elseif self.motion < 0 and self.velocity.x > self.motion then
			x = x-min(0,self.motion*dt-self.velocity.x)*self.drag
		end

		-- horizontal
		if self.velocity.x ~= 0 then
			local u = self.velocity.x/abs(self.velocity.x)
			local tile,hit = Line:new(p,p+Vector2:new(self.velocity.x+self.hitbox.x/2*u,0)):mapIntersect(self.map)
			if tile then
				self.position.x = hit.x-self.hitbox.x/2*u
				self.velocity.x = -self.velocity.x/2
				x = -x
			end
		end

		-- vertical
		local u = self.velocity.y < 0 and -1 or 0
		local tile,hit = Line:new(p,self.position+Vector2:new(0,self.velocity.y+self.hitbox.y*u)):mapIntersect(self.map)
		if tile then
			self.position.y = hit.y-self.hitbox.y*u
			if u == 0 then
				x = (self.velocity.x-self.motion*dt)*tile.friction
				y = max(0,self.velocity.y)
			else self.velocity.y = -self.velocity.y/2
				y = -y
			end
		end
		self.ground = u == 0 and tile or nil

		-- move

		self.velocity = self.velocity-Vector2:new(x,y)
		self.position = self.position+self.velocity

		-- tile

		if self.map then
			local offset = Vector2:new(floor(self.position.x/self.map.size),floor((self.position.y-self.hitbox.y/2)/self.map.size))
			local tile = self.map.tile[offset.x+self.map.x*offset.y]
			if offset.x >= 0 and offset.x < self.map.x and offset.y >= 0 and offset.y < self.map.y and tile and tile.collision then
				local rect = Rect:new(offset*self.map.size,Vector2:new(self.map.size,self.map.size))
				local collide,hit = rect:collide(self:rect())
				if collide then
					self.position = self.position+hit
				end
			end
		end

		self:animate()
		if self.image then
			self.image:update(dt)
		end
	end,
	draw = function(self,x,y,angle,sx,sy)
		if self.image then
			local pos = self.position-Vector2:new(self.image.width/2,self.image.height)
			self.image:draw(pos.x*sx+x,pos.y*sy+y,angle,sx,sy)
		end
	end
})

local function render(self,img,x,y,angle,sx,sy,...)
	local joint = self.joint[img]
	local pos,rot

	if joint.anchor == self then
		pos = self.position-Vector2:new(0,self.hitbox.y/2)
		rot = self.rotation
	else local anchor = self.joint[joint.anchor]
		pos = anchor.position
		rot = anchor.rotation
	end

	joint.position = pos+joint.origin:rotateToVectorSpace(Vector2:new(),rot)+joint.offset:rotateToVectorSpace(Vector2:new(),rot+joint.rotation)
	rot = rot+joint.rotation

	img:draw((joint.position.x-img.width/2)*sx+x,(joint.position.y-img.height/2)*sy+y,rot+angle,sx,sy,...)
end

local recursive

recursive = function(self,v,list,check,...)
	check[v] = true
	render(self,v,...)
	if list[v] then
		for _,v in pairs(list[v]) do
			recursive(self,v,list,check,...)
		end
		list[v] = nil
	end
end

local Doll = Entity:class("Doll",3)({
	joint = {},
	getJoint = function(self,joint)
		return self.joint[joint]
	end,
	addJoint = function(self,anchor,joint,origin,offset)
		if (anchor == self or self.joint[anchor]) and anchor ~= joint and not self.joint[joint] then
			self.joint[joint] = {
				anchor = anchor,
				origin = origin,
				offset = offset,
				position = Vector2:new(),
				rotation = 0
			}

			return self.joint[joint]
		end
	end,
	remJoint = function(self,joint)
		if self.joint[joint] then
			for k,v in pairs(self.joint) do
				if k == joint then
					self.joint[k] = nil
				elseif v.anchor == joint then
					self:remJoint(k)
				end
			end
		end
	end,
	draw = function(self,...)
		local list = {}
		local check = {}
		check[self] = true
		for k,v in pairs(self.joint) do
			if check[v.anchor] then
				recursive(self,k,list,check,...)
			else if not list[v.anchor] then
					list[v.anchor] = {}
				end
				table.insert(list[v.anchor],k)
			end
		end
	end
})

local Projectile = Rigid:class("Projectile",3)({
	hit = nil,
	list = {},
	whitelist = false,
	lifespan = 300,
	thrust = Vector2:new(),
	force = Vector2:new(),
	addList = function(self,...)
		for _,v in pairs({...}) do
			self.list[v] = true
		end
	end,
	remList = function(self,...)
		for _,v in pairs({...}) do
			self.list[v] = nil
		end
	end,
	update = function(self,dt)
		self.lifespan = self.lifespan-dt
		if self.lifespan > 0 then
			if not self.hit and self.map then
				local thrust = self.thrust:rotateToVectorSpace(Vector2:new(),self.rotation)
				local g = self.map and self.map.gravity or Vector2:new()
				local x = (self.velocity.x-g.x-self.force.x-thrust.x)*self.drag*dt
				local y = -(self.force.y+thrust.y+g.y)*self.weight*dt

				self.velocity = self.velocity-Vector2:new(x,y)
				self.rotation = atan2(self.velocity.y,self.velocity.x)

				local dir = self.position+self.velocity+Vector2:new(self.hitbox.x/2,0):rotateToVectorSpace(Vector2:new(),self.rotation)

				-- Entity

				local hit,pos
				for v,_ in pairs(self.whitelist and self.list or self.map.entity) do
					pos = lemon.line.rectIntersect(self.position,dir,v:rect())
					if pos and (self.whitelist or not self.list[v]) then
						hit = v
					end
				end

				-- Tile

				if not hit then
					hit,pos = Line:new(
						self.position,
						dir
					):mapIntersect(self.map)
				end

				if hit then
					self.position = pos
					self.hit = hit
					self.projectileHit:fire(hit,pos)
				else self.position = self.position+self.velocity
				end
			end
		else self.projectileExpired:fire()
			self:destroy()
		end
	end,
	draw = function(self,x,y,angle,sx,sy,...)
		if self.image then
			local pos = self.position-Vector2:new(self.image.width,self.image.height)/2
			self.image:draw(x+pos.x*sx,y+pos.y*sy,angle+self.rotation,sx,sy,...)
		end
	end,
	projectileHit = Instance.event,
	projectileExpired = Instance.event
})
