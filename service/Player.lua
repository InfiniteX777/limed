local game = Instance:service"GameInterface"
local content = Instance:service"ContentService"
local input = Instance:service"UserInput"

local down = love.keyboard.isDown
local fireDir = 0
local fire = false

local player = Instance:class("Player",2){
	character = nil,
	controlEnabled = true,
	control = {
		up = "w",
		down = "s",
		left = "a",
		right = "d",
		acc1 = "1",
		acc2 = "2",
		acc3 = "3",
		acc4 = "4",
		acc5 = "5",
		acc6 = "6",
		inventory = "tab",
		attack = 1
	},
	stats = {
		strength = 0,
		agility = 0,
		intelligence = 0
	},
	armor = nil,
	weapon = nil,
	accessory = {},
	inventory = {}
}

input.mouseWheel:connect(function(x,y)
	if not game.hoveredUI then
		game.scale = math.max(0.5,math.min(game.scale-y/5,5))
	end
end)

input.keyDown:connect(function(key)
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
		elseif key == ctrl.inventory then
			local window = require("assets.scripts.ui.inventory")
			window.visible = not window.visible
			window.active = not window.active
		elseif key == "q" then
			char.map.drawPoints = not char.map.drawPoints
		elseif key == "e" then
			game.showStats = not game.showStats
		elseif key == "r" then
			game:tremor(Vector2:new(char.body:getPosition()),256,64)
		elseif key == "f11" then
			love.window.setFullscreen(not love.window.getFullscreen())
		end
	end
end)

input.keyUp:connect(function(key)
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
		local gx,gy = game:getFocus():components()
		local x,y = char.body:getLocalVector((x-gx)/game.scale,(y-gy)/game.scale)
		fireDir = Vector2:new(x-char.body:getX(),y-char.body:getY())
	end
end

input.mouseDown:connect(function(x,y,button)
	if button == player.control.attack and game.ui:getSelected() == game.ui then
		fire = true
		boom(x,y)
	end
end)

input.mouseMoved:connect(function(x,y)
	if fire then
		boom(x,y)
	end
end)

input.mouseUp:connect(function(x,y)
	fire = false
end)

local function shoot(angle)
	local char = player.character
	local map = char.map
	local body = love.physics.newBody(map.world,char.body:getX(),char.body:getY(),"dynamic")
	local image = content:loadImage("assets/projectile/arrow.png")
	local shape = love.physics.newRectangleShape(0,0,25,5,0)
	local arrow = map:projectile(1,body,image,char)

	love.physics.newFixture(body,shape)
	arrow.list[char] = true
	arrow.lifespan = 1
	body:setMassData(0,0,1,0)
	local dir = fireDir:rotate(Vector2:new(),angle)
	body:applyLinearImpulse(dir.x*16,dir.y*16)
	body:setMassData(0,0,lemon.least,0)
	arrow.projectileHit:connect(function(hit,fixture,col)
		game:tremor(Vector2:new(arrow.body:getPosition()),4,8,32)
		arrow:destroy()
	end)
end

game.gameUpdate:connect(function(dt)
	local char = player.character
	if fire and char then
		local angle = math.atan2(fireDir.y,fireDir.x)
		for i=0,10 do
			shoot(i/10*math.pi*2)
		end
	end
end)
