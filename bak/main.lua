require("conf")
require("module.limed.init")
local ContentService = Instance:service("ContentService")
local InputService = Instance:service("InputService")
local grassydirt,grass,a,b,level,t,UI,player

local fire
local fireDir = Vector2:new(1,0)
local scale = 1
local rot = 0
function love.load()
	grassydirt = ContentService:loadImage("assets/tile/grassydirt.png")
	grass = ContentService:loadImage("assets/tile/grass1.png")
	grassydirt:bake(48,48)
	grass:bake(32,32)
	a = grass:sprite(32,32)
	a.bounce = true
	a:play()
	b = a:clone(function(self)
		self:seek(nil,1)
	end)
	level = Instance:new("Map",function(self)
		self.x = 32
		self.y = 32
	end)
	t = Instance:new("Tile")
	level:add(t:clone(function(self)
		self.image = a
		self.collision = false
	end),0,5)
	level:add(t:clone(function(self)
		self.image = b
		self.collision = false
	end),1,5)
	level:add(t:clone(function(self)
		self.image = a
		self.collision = false
	end),2,5)
	level:add(t:clone(function(self)
		self.image = grassydirt:quad(48,48)
	end),4,5)
	level:add(t:clone(function(self)
		self.image = grassydirt:quad(48,48)
	end),0,6)
	level:add(t:clone(function(self)
		self.image = grassydirt:quad(48,48,1)
	end),1,6)
	level:add(t:clone(function(self)
		self.image = grassydirt:quad(48,48,4)
	end),2,6)
	level:add(t:clone(function(self)
		self.image = grassydirt:quad(48,48,2)
	end),3,6)
	level:add(t:clone(function(self)
		self.image = grassydirt:quad(48,48,0,1)
	end),0,7)
	level:add(t:clone(function(self)
		self.image = grassydirt:quad(48,48,1,1)
	end),1,7)
	level:add(t:clone(function(self)
		self.image = grassydirt:quad(48,48,4,1)
	end),2,7)
	level:add(t:clone(function(self)
		self.image = grassydirt:quad(48,48,2,1)
	end),3,7)
	level:add(t:clone(function(self)
		self.image = grassydirt:quad(48,48,0,2)
	end),0,8)
	level:add(t:clone(function(self)
		self.image = grassydirt:quad(48,48,1,2)
	end),1,8)
	level:add(t:clone(function(self)
		self.image = grassydirt:quad(48,48,4,2)
	end),2,8)
	level:add(t:clone(function(self)
		self.image = grassydirt:quad(48,48,2,2)
	end),3,8)
	for i=2,32 do
		level:add(t:clone(function(self)
			self.image = grassydirt:quad(48,48,1)
		end),i,6)
	end

	for i=1,32 do
		level:add(t:clone(function(self)
			self.image = grassydirt:quad(48,48,1)
		end),i,2)
	end
	UI = Instance:new("UI")
	frame = Instance:new("Label",function(self)
		self.text = "Hello There! Hello World!"
		self.textWrap = false
		self.textAlign = "topright"
		self.textColor = Color:new(255,0,0)
		self.image = a
		self.scale.size = Vector2:new(0.25,0.25)
		self.scale.position.x = 0.375
		self.scale.position.y = 0.375
		self.outlineColor.r = 255
	end)
	UI:add(frame)
	player = require("assets.scripts.entity.stella")()
	--[[player = Instance:new("Doll",function(self)
		self.hitbox = Vector2:new(32,32)
		self.image = ContentService:loadImage("assets/tile/box.png")
		local arm = ContentService:loadImage("assets/tile/box.png")
		local hand = ContentService:loadImage("assets/tile/box.png")
		self:addJoint(self,arm,Vector2:new(0,16),Vector2:new(0,16))
		self:getJoint(arm).rotation = math.pi/4
		self:addJoint(arm,hand,Vector2:new(0,16),Vector2:new(0,16))
		self:getJoint(hand).rotation = math.pi/4
	end)]]
	level:add(player)
	bob = require("assets.scripts.entity.stella")(function(self)
		self.position = Vector2:new(50,0)
		self.motion = 160
	end)
	level:add(bob)
	local function boom(x,y)
		local screen = Vector2:new(love.graphics.getDimensions())
		fireDir = Vector2:new(x,y)-screen/2
	end
	InputService.mouseDown:connect(function(x,y,button)
		if button == 1 then
			fire = true
			boom(x,y)
		end
	end)
	InputService.mouseMoved:connect(function(x,y)
		if fire then
			boom(x,y)
		end
	end)
	InputService.mouseUp:connect(function(x,y)
		fire = false
	end)
	InputService.mouseWheel:connect(function(x,y)
		scale = math.max(0.5,math.min(scale-y/5,5))
	end)
	local m = 0
	InputService.keyDown:connect(function(key)
		if key == "a" then
			player.motion = player.motion-160
		end
		if key == "d" then
			player.motion = player.motion+160
		end
		if key == "w" then
			player.velocity.y = -5
		end
		if key == "q" then
			player:push(Vector2:new(-50,0))
		end
		if key == "e" then
			player:push(Vector2:new(50,0))
		end
	end)
	InputService.keyUp:connect(function(key)
		if key == "a" then
			player.motion = player.motion+160
		elseif key == "d" then
			player.motion = player.motion-160
		end
	end)
end

local t = 0
function love.update(dt)
	level:update(dt)
	--UI:update(dt)
	t = t+dt
	if t > 1 then
		t = 0
		bob.motion = -bob.motion
	end
	collectgarbage()
end

function love.draw()
	local width,height = love.graphics.getDimensions()
	local pos = player.position-Vector2:new(0,player.hitbox.y/2)
	pos = pos:rotateToVectorSpace(Vector2:new(level.x,level.y)*level.size/2,rot)*scale-Vector2:new(width,height)/2
	level:draw(-pos.x,-pos.y,rot,scale,scale)
	--UI:draw(0,0,math.pi/4,scale,scale)

	if fire then
		local p = player.position-Vector2:new(0,player.hitbox.y/2)
		level:add(Instance:new("Projectile",function(self)
			self.lifespan = 5
			self.position = p:clone()
			self.velocity = fireDir/scale/9.81
			self.hitbox = Vector2:new(25,5)
			self.image = ContentService:loadImage("assets/projectile/arrow.png")
			self.map = level
			self:addList(player)
			self.projectileHit:connect(function()
				self.lifespan = math.min(1,self.lifespan)
			end)
			self.projectileExpired:connect(function()
				level:rem(self)
			end)
		end))
	end

	-- Stats
	love.graphics.origin()
	local n = 1
	for k,v in pairs(love.graphics.getStats()) do
		if k == "texturememory" then
			v = v/1024
		end
		love.graphics.setColor(0,0,0)
		love.graphics.print(k.." = "..tostring(v)..(k == "texturememory" and " kB" or ""), 12,32+n*20)
		love.graphics.setColor(255,255,255)
		love.graphics.print(k.." = "..tostring(v)..(k == "texturememory" and " kB" or ""), 10,30+n*20)
		n = n+1
	end
	love.graphics.print("FPS: "..love.timer.getFPS(), 10,30)
	love.graphics.print('Memory actually used (in mB): ' .. collectgarbage('count')/1024, 10,10)
	collectgarbage()
end