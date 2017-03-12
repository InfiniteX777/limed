local insert = table.insert

local path = (...) and (...):gsub("%.init$",""):gsub("%.","/") or ""

local class = {}
local queue = {}

Instance = {}
Instance.__index = Instance

-- Miscellaneous

local function empty() end

-- Event Constructor

local event = {}
event.__index = event
event.__event = true

function event:fire(...)
	for k,v in pairs(self) do
		if v then
			k:fire(...)
		else self:disconnect(k)
		end
	end
end

function event:connect(callback)
	local v = Instance:new("Hook")
	v.event = self
	v.callback = callback
	self[v] = true
end

function event:disconnect(hook)
	if self[hook] then
		self[hook] = nil
		hook:destroy()
	end
end

function event:disconnectAll()
	for k,v in pairs(self) do
		self:disconnect(k)
	end
end

function Instance:event()
	return setmetatable({},event)
end

-- Construction
function Instance:class(name,security)
	if not class[name] then
		local security = security or 3
		return function(t)
			local t = t or {}
			t.__index = t

			for k,v in pairs(t) do
				if type(v) == "function" then
					local f = v
					t[k] = function(child,...)
						return f(child,self,...)
					end
				end
			end

			t.name = function()
				return name
			end

			t.security = function()
				return security
			end

			t.is = function(t,ref,recursive)
				recursive = recursive == nil or recursive
				return name == ref or recursive and self:is(ref)
			end

			t.constructor = t.new

			t.new = nil

			class[name] = setmetatable(t,self)

			if queue[k] then
				for _,v in pairs(queue[k]) do v() end
				queue[k] = nil
			end

			return t
		end
	else print("Class '"..name.."' already exists!")
	end
end

function Instance:api(meta)
	local meta = meta or {}

	local index = meta.__index
	meta.__index = function(self,k)
		local mv = rawget(meta,k)

		if type(mv) == "table" then
			return mv
		elseif type(mv) == "function" then
			return function(_,...)
				return mv(self,...)
			end
		end

		local v = rawget(rawget(self,"__data"),k)

		if index then
			return index(self,k,v)
		end

		return v
	end

	local newindex = meta.__newindex
	meta.__newindex = function(self,k,v)
		if newindex then
			v = newindex(self,k,v)
		end

		rawset(self,k,nil)
		rawset(rawget(self,"__data"),k,v)

		if self.__callback then
			self:__callback(k,v)
		end
	end

	local constructor = meta.new or empty
	meta.new = function(self,...)
		local t = setmetatable({__data = {}},meta)

		constructor(t,...)

		return t
	end

	return meta
end

function Instance:new(name,prop)
	if name and class[name] then
		local security = class[name]:security()
		local superName = self:name()
		if security == 3 then -- Creating object classes with root class.
			return class[name]:construct(prop)
		elseif security == 4 and self:security() == 2 then -- Creating reference classes with service classes.
			return class[name]:construct(prop)
		elseif class[name]:is(superName) and name ~= superName then -- Creating descendant classes with ancestral classes.
			return class[name]:construct(function(n)
				for k,v in pairs(self) do
					if type(v) == "table" and v ~= self and v ~= n then
						n[k] = lemon.table.copy(v,nil,true)
					else n[k] = v
					end
				end
				if prop then
					prop(n)
				end
			end)
		else print("Unable to instantiate class '"..name.."' with class '"..superName.."'. Security level is "..class[name]:security()..".")
		end
	else print("Class '"..name.."' does not exist!")
	end
end

function Instance:service(name)
	if class[name] and class[name]:security() == 2 then
		return class[name]
	end
end

-- Default
function Instance:name()
	return "Instance"
end

function Instance:security()
	return 1
end

function Instance:is(name)
	return self:name() == name
end

function Instance:clone(prop)
	return self:construct(function(t)
		lemon.table.copy(self,t,true)
		if prop then
			prop(n)
		end
	end)
end

function Instance:destroy()
	--self.destroyed:fire()

	for k,v in pairs(self) do
		if type(v) == "table" and v.__event then
			v:disconnectAll()
		end
		self[k] = nil
	end
end

Instance.update = empty
Instance.draw = empty
Instance.constructor = empty

function Instance:construct(prop)
	local t = setmetatable({},self)
	local meta = self
	while meta ~= nil do
		for k,v in pairs(meta) do
			if type(v) == "table" and v ~= t and k ~= "__index" then
				t[k] = lemon.table.copy(v,nil,true)
			end
		end
		meta = getmetatable(meta)
	end

	self.constructor(t)

	if prop then
		prop(t)
	end

	return t
end

-- API
function Instance:waitFor(...)
	local l = {...}
	local d = #l-1

	local function callback()
		d = d-1

		if d == 0 then
			l[#l]()
		end
	end

	for i=1,#l-1 do
		local name = l[i]
		if class[name] then
			callback()
		else if not queue[name] then
				queue[name] = {}
			end
			insert(queue[name],callback)
		end
	end
end

-- Event
--Instance.destroyed = Instance:event()

--[[ Init ]
	Pattern:
	- All APIs
	- 'Hook' class
	- 'GameInterface' class
	- 'ContentService' class
	- 'UserInput' class
	- All 'Service' classes
	- All 'Reference' classes
	- All Object' classes
]]
local function load(...)
	for _,v in pairs({...}) do
		require(v)
	end
end

local function batch(...)
	for _,t in pairs({...}) do
		for _,v in pairs(love.filesystem.getDirectoryItems(path.."/"..t)) do
			load(path.."."..t.."."..v:gsub("%.lua$",""))
		end
	end
end

batch("api")
load(path..".object.Hook")
load(path..".service.GameInterface")
load(path..".service.ContentService")
load(path..".service.UserInput")
batch("service","reference","object")

--[[ Callbacks ]]

local game = Instance:service"GameInterface"
local content = Instance:service"ContentService"
local graphics = Instance:service"GraphicsInterface"
local input = Instance:service"UserInput"

function love.resize(w,h)
	game.window = Vector2:new(w,h)
	game.gameResize:fire(w,h)
	collectgarbage()
end

function love.update(dt)
	game.time = game.time+dt

	for k,_ in pairs(game.tremors) do
		if k.magnitude <= k.threshold then
			game.tremors[k] = nil
		else k:update(dt)
		end
	end

	if game.map then
		game.map:update(dt)
	end

	if game.ui then
		game.ui:update(dt)
	end

	game.gameUpdate:fire(dt)
	collectgarbage()
end

function love.quit()
	game.gameQuit:fire()
	collectgarbage()

	return game:quitCallback()
end

local function gprint(t,x,y)
	graphics:pushColor(0,0,0)
	love.graphics.print(t,x+2,y+2)
	graphics:popColor()
	love.graphics.print(t,x,y)
end

function love.draw()
	if game.map then
		local focus = game:getFocus()

		game.map:draw(focus.x,focus.y,0,game.scale,game.scale)
	end

	if game.ui then
		game.ui:draw(0,0)
	end

	game.gameDraw:fire()
	love.graphics.origin()
	graphics:resetColor()

	if game.showStats then
		content:resetFont()
		gprint("Memory Usage: "..(collectgarbage("count")/1024).." mB",10,10)
		gprint("FPS: "..love.timer.getFPS(),10,30)
		gprint("Lifetime: "..game.time,10,50)
		local n = 2
		for k,v in pairs(love.graphics.getStats()) do
			if k == "texturememory" then
				v = v/1024
			end
			local s = k.." = "..tostring(v)..(k == "texturememory" and " kB" or "")
			gprint(s,10,30+n*20)
			n = n+1
		end
	end

	collectgarbage()
end

function love.keypressed(...)
	input.keyDown:fire(...)
	collectgarbage()
end

function love.keyreleased(...)
	input.keyUp:fire(...)
	collectgarbage()
end

function love.mousepressed(...)
	input.mouseDown:fire(...)
	collectgarbage()
end

function love.mousereleased(...)
	input.mouseUp:fire(...)
	collectgarbage()
end

function love.mousemoved(...)
	input.mouseMoved:fire(...)
	collectgarbage()
end

function love.wheelmoved(...)
	input.mouseWheel:fire(...)
	collectgarbage()
end

function love.touchpressed(...)
	input.touchDown:fire(...)
	collectgarbage()
end

function love.touchreleased(...)
	input.touchUp:fire(...)
	collectgarbage()
end

function love.touchmoved(...)
	input.touchMoved:fire(...)
	collectgarbage()
end
