local alignment = {
	topleft = {0,0,"left"},
	middleleft = {0,-0.5,"left"},
	bottomleft = {0,-1,"left"},
	topcenter = {0.5,0,"center"},
	middlecenter = {0.5,-0.5,"center"},
	bottomcenter = {0.5,-1,"center"},
	topright = {1,0,"right"},
	middleright = {1,-0.5,"right"},
	bottomright = {1,-1,"right"}
}

local FontAsset = Instance:class("FontAsset",4)({
	font = nil,
	text = "",
	align = "topleft",
	color = Color:new(),
	wrap = nil,
	draw = function(self,super,x,y,angle,sx,sy)
		local font = self.font
		local width = love.graphics.getDimensions()
		local height = font:getHeight()*sy
		local pos = Vector2:new(x,y):rotateToVectorSpace(Vector2:new(),-angle)
		local offset,direction,align = unpack(alignment[self.align])
		offset = offset*sx
		love.graphics.push()
		love.graphics.setColor(self.color:components())
		love.graphics.rotate(angle)

		if self.wrap then
			local _,list = font:getWrap(self.text,self.wrap)
			direction = #list*direction
			love.graphics.printf(table.concat(list,"\n"),pos.x-width*offset,pos.y+height*direction,width,align,0,sx,sy)
		else love.graphics.printf(self.text,pos.x-width*offset,pos.y+height*direction,width,align,0,sx,sy)
		end
		love.graphics.pop()
	end
})