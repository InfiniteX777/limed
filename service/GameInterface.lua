local random,pi,cos,sin,max = math.random,math.pi,math.cos,math.sin,math.max

local game = Instance:class("GameInterface",2){
	scale = 1,
	angle = 0,
	ui = nil,
	map = nil,
	tremors = {},
	focus = Vector2:new(),
	window = Vector2:new(love.graphics.getDimensions()),
	showStats = true,
	time = 0,
	quitCallback = function() end,
	focusBody = function(self,super,body)
		self.focus:set(body:getPosition())
	end,
	getFocus = function(self,super)
		local angle = random()*pi*2
		local focus = self.focus
		local mag = 0
		local shake = Vector2:new(cos(angle),sin(angle))

		for k,_ in pairs(self.tremors) do
			local d = k.magnitude

			if k.source then
				d = d/max(1,(focus-k.source).mag-k.radius/2)
			end

			if d <= k.threshold then
				d = 0
			end

			mag = mag+d
		end

		return self.window/2-(focus+shake*mag)*self.scale
	end,
	tremor = function(self,super,source,magnitude,intensity,radius,threshold)
		local tremor = self:new("Tremor")
		tremor.source = source
		tremor.magnitude = magnitude
		tremor.intensity = intensity or 4
		tremor.radius = radius or 64
		tremor.threshold = threshold or 0.1

		self.tremors[tremor] = true

		return tremor
	end,
	setQuitCallback = function(self,super,callback)
		self.quitCallback = callback
	end,
	gameResize = Instance:event(),
	gameUpdate = Instance:event(),
	gameDraw = Instance:event(),
	gameQuit = Instance:event()
}
