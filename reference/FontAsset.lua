local content = Instance:service("ContentService")
local game = Instance:service("GameInterface")

local FontAsset = Instance:class("FontAsset",4){
	font = nil,
	text = ColoredText:new(),
	align = "topleft",
	wrap = nil,
	draw = function(self,super,x,y,angle,sx,sy,...)
		local text = self.text

		if text.abs:len() == 0 then return end

		local angle,sx,sy = angle or 0,sx or 1,sy or 1
		local font = self.font
		local height = font:getHeight()
		local offset,direction,align = unpack(content.fontAlignment[self.align])

		love.graphics.push()
		love.graphics.translate(x,y)
		love.graphics.scale(sx,sy)
		love.graphics.rotate(angle)
		love.graphics.setFont(font)

		if self.wrap then
			local _,list = font:getWrap(text.abs,self.wrap)
			direction = #list*direction
			love.graphics.printf(text.colored,0,-height*direction,self.wrap,align,0,1,1,...)
		else local width = love.graphics.getDimensions()
			love.graphics.printf(text.colored,-width*offset,-height*direction,width,align,0,1,1,...)
		end
		love.graphics.pop()
	end
}
