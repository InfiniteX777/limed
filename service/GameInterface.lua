local down = love.keyboard.isDown

local GameInterface = Instance:class("GameInterface",2)({
	scale = 1,
	angle = 0,
	x = 0,
	y = 0,
	isDown = function(self,super,key)
		return type(key) == "number" and love.mouse.isDown(key) or down(key)
	end,
	isShift = function(self,super)
		return down("lshift","rshift")
	end,
	isCtrl = function(self,super)
		return down("lctrl","rctrl")
	end,
	isAlt = function(self,super)
		return down("lalt","ralt")
	end,
	gameUpdate = Instance:event(),
	gameDraw = Instance:event(),
	keyDown = Instance:event(),
	keyUp = Instance:event(),
	mouseDown = Instance:event(),
	mouseUp = Instance:event(),
	mouseMoved = Instance:event(),
	mouseWheel = Instance:event(),
	touchDown = Instance:event(),
	touchUp = Instance:event(),
	touchMoved = Instance:event()
})

function love.update(...)
	GameInterface.gameUpdate:fire(...)
	collectgarbage()
end

function love.draw(...)
	GameInterface.gameDraw:fire(...)
end

function love.keypressed(...)
	GameInterface.keyDown:fire(...)
end

function love.keyreleased(...)
	GameInterface.keyUp:fire(...)
end

function love.mousepressed(...)
	GameInterface.mouseDown:fire(...)
end

function love.mousereleased(...)
	GameInterface.mouseUp:fire(...)
end

function love.mousemoved(...)
	GameInterface.mouseMoved:fire(...)
end

function love.wheelmoved(...)
	GameInterface.mouseWheel:fire(...)
end

function love.touchpressed(...)
	GameInterface.touchDown:fire(...)
end

function love.touchreleased(...)
	GameInterface.touchUp:fire(...)
end

function love.touchmoved(...)
	GameInterface.touchMoved:fire(...)
end