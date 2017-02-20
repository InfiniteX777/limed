local down = love.keyboard.isDown
local fireDir = 0
local fire = false

local player = Instance:class("Player",2)({
	character = nil,
	controlEnabled = true,
	control = {
		up = "w",
		down = "s",
		left = "a",
		right = "d",
		attack = 1
	}
})

Instance:waitFor("GameInterface",function()
	local game = Instance:service("GameInterface")
	local content = Instance:service("ContentService")

	game.mouseWheel:connect(function(x,y)
		game.scale = math.max(0.5,math.min(game.scale-y/5,5))
	end)
	game.keyDown:connect(function(key)
		local char = player.character
		local ctrl = player.control
		if char then
			if key == ctrl.left then
				char.motion = char.motion-2
			elseif key == ctrl.right then
				char.motion = char.motion+2
			elseif key == ctrl.up and char:isGrounded() then
				local s = -32*12
				char.body:applyLinearImpulse(0,s)
				for col,hit in pairs(char.ground) do
					local x,y = col:getNormal()
					hit.body:applyLinearImpulse(x*s,y*s)
				end
			elseif key == ctrl.down then
				char.platform = true
				char.body:setAwake(true)
			end
		end
	end)
	game.keyUp:connect(function(key)
		local char = player.character
		local ctrl = player.control
		if char then
			if key == ctrl.left then
				char.motion = char.motion+2
			elseif key == ctrl.right then
				char.motion = char.motion-2
			elseif key == ctrl.down then
				char.platform = false
			end
		end
	end)

	local function boom(x,y)
		local char = player.character
		if char then
			local x,y = char.body:getLocalVector((x-game.x)/game.scale,(y-game.y)/game.scale)
			fireDir = Vector2:new(x,y)-Vector2:new(char.body:getX(),char.body:getY())
		end
	end
	game.mouseDown:connect(function(x,y,button)
		if button == player.control.attack then
			fire = true
			boom(x,y)
		end
	end)
	game.mouseMoved:connect(function(x,y)
		if fire then
			boom(x,y)
		end
	end)
	game.mouseUp:connect(function(x,y)
		fire = false
	end)

	local function shoot(angle)
		local char = player.character
		local map = char.world
		local body = love.physics.newBody(map.world,char.body:getX(),char.body:getY(),"dynamic")
		local image = content:loadImage("assets/projectile/arrow.png")
		local arrow = map:projectile(1,body,image,char)

		local shape = love.physics.newRectangleShape(0,0,25,5,0)
		local fixture = love.physics.newFixture(body,shape)

		arrow.list[char] = true
		arrow.lifespan = 1
		body:setMassData(0,0,1,0)
		local dir = fireDir:rotateToVectorSpace(Vector2:new(),angle)
		body:applyLinearImpulse(dir.x*16,dir.y*16)
		body:setMassData(0,0,lemon.least,0)
		arrow.projectileHit:connect(function(hit,fixture,col)
			arrow:destroy()
		end)
	end
	game.gameUpdate:connect(function(dt)
		local char = player.character
		if fire and char then
			local angle = math.atan2(fireDir.y,fireDir.x)
			for i=0,9 do
				shoot(i/10*math.pi*2)
			end
		end
	end)
end)