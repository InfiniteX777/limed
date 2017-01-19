--[[ InputService ]
Inherits: Instance

Description: Handles user input.

Properties:
	Table modifier - If any shift, CTRL or ALT is being held by the user.

Functions:
	Boolean isShift() - Returns if any of the shift keys are being held by the user.

	Boolean isCtrl() - Returns if any of the CTRL keys are being held by the user.

	Boolean isAlt() - Returns if any of the ALT keys are being held by the user.

Events:
	keyDown( - Fires when a key is pressed.
		String key - The key.
		String scancode - Scancode of the key.
		Boolean isrepeat - If it is being repeated by the system.
	)

	keyUp( - Fires when a key is released.
		String key - The key.
		String scancode - Scancode of the key.
	)

	mouseDown( - Fires when one of the buttons of the mouse are pressed.
		Integer x - Position x.
		Integer y - Position y.
		Number button - The button. 1: primary/left; 2: secondary/right; 3: middle
		Boolean istouch - Touchscreen.
	)

	mouseUp( - Fires when one of the buttons of the mouse are released.
		Integer x - Position x.
		Integer y - Position y.
		Number button - The button. 1: primary/left; 2: secondary/right; 3: middle
		Boolean istouch - Touchscreen.
	)

	mouseMoved( - Fires when the mouse is moved.
		Integer x - Position x.
		Integer y - Position y.
		Integer dx - Translation from the previous position x.
		Integer dy - Translation from the previous position y.
		Boolean istouch - Touchscreen.
	)

	mouseWheel( - Fires when the mouse wheel is moved.
		Integer x - Horizontal translation.
		Integer y - Vertical translation.
	)

	touchDown( - Fires when a touchscreen is touched.
		light_userdata id - Unique identier for the touch press.
		Integer x - Position x.
		Integer y - Position y.
		Integer dx - Translation from the previous position x. Since this is the first touch press, this is always 0.
		Integer dy - Translation from the previous position y. Since this is the first touch press, this is always 0.
		Number pressure - How hard it is being pressed. If the device is not touch-sensitive, it will return 1.
	)

	touchUp( - Fires when a touchscreen is released.
		light_userdata id - Unique identier for the touch press.
		Integer x - Position x.
		Integer y - Position y.
		Integer dx - Translation from the previous position x.
		Integer dy - Translation from the previous position y.
		Number pressure - How hard it is being pressed. If the device is not touch-sensitive, it will return 1.
	)

	touchMoved( - Fires when a touch press is moved.
		light_userdata id - Unique identier for the touch press.
		Integer x - Position x.
		Integer y - Position y.
		Integer dx - Translation from the previous position x.
		Integer dy - Translation from the previous position y.
		Number pressure - How hard it is being pressed. If the device is not touch-sensitive, it will return 1.
	)
]]
local InputService = Instance:class("InputService",2)({
	modifier = {},
	isShift = function(self)
		return self.modifier.lshift == true or self.modifier.rshift == true
	end,
	isCtrl = function(self)
		return self.modifier.lctrl == true or self.modifier.rctrl == true
	end,
	isAlt = function(self)
		return self.modifier.lalt == true or self.modifier.ralt == true
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
})

local modifier = {"lshift","rshift","lctrl","rctrl","lalt","ralt"}
for k,v in pairs(modifier) do
	modifier[v] = true
end

InputService.keyDown:connect(function(key)
	if modifier[key] then
		InputService.modifier[key] = true
	end
end)

InputService.keyUp:connect(function(key)
	if modifier[key] then
		InputService.modifier[key] = nil
	end
end)

function love.keypressed(...)
	InputService.keyDown:fire(...)
end

function love.keyreleased(...)
	InputService.keyUp:fire(...)
end

function love.mousepressed(...)
	InputService.mouseDown:fire(...)
end

function love.mousereleased(...)
	InputService.mouseUp:fire(...)
end

function love.mousemoved(...)
	InputService.mouseMoved:fire(...)
end

function love.mousewheel(...)
	InputService.mouseWheel:fire(...)
end

function love.touchpressed(...)
	InputService.touchDown:fire(...)
end

function love.touchreleased(...)
	InputService.touchUp:fire(...)
end

function love.touchmoved(...)
	InputService.touchMoved:fire(...)
end