local down = love.keyboard.isDown

local input = Instance:class("UserInput",2){
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
	keyDown = Instance:event(),
	keyUp = Instance:event(),
	mouseDown = Instance:event(),
	mouseUp = Instance:event(),
	mouseMoved = Instance:event(),
	mouseWheel = Instance:event(),
	touchDown = Instance:event(),
	touchUp = Instance:event(),
	touchMoved = Instance:event()
}
