local hori = {
	center = function(pos,screen)
		return Vector2:new(pos.x-screen/2,pos.y)
	end,
	right = function(pos,screen)
		return Vector2:new(pos.x-screen,pos.y)
	end
}

local alignment = {
	topleft = function(pos)
		return pos,0,"left"
	end,
	middleleft = function(pos)
		return pos,-0.5,"left"
	end,
	bottomleft = function(pos)
		return pos,-1,"left"
	end,
	topcenter = function(...)
		return hori.center(...),0,"center"
	end,
	middlecenter = function(...)
		return hori.center(...),-0.5,"center"
	end,
	bottomcenter = function(...)
		return hori.center(...),-1,"center"
	end,
	topright = function(...)
		return hori.right(...),0,"right"
	end,
	middleright = function(...)
		return hori.right(...),-0.5,"right"
	end,
	bottomright = function(...)
		return hori.right(...),-1,"right"
	end
}

local FontAsset = Instance:class("FontAsset",4)({
	font = nil,
	text = "",
	align = "topleft",
	color = Color:new(),
	wrap = nil,
	draw = function(self,x,y,angle,sx,sy)
		local screen = love.graphics.getDimensions()/(sx^2)
		local font = self.font
		local height = font:getHeight()*sy
		local pos,direction,align = alignment[self.align](
			Vector2:new(x,y):rotateToVectorSpace(Vector2:new(),-angle),
			screen
		)
		love.graphics.setColor(self.color:components())
		love.graphics.rotate(angle)

		if self.wrap then
			local _,list = font:getWrap(self.text,self.wrap)
			direction = #list*direction
			love.graphics.printf(table.concat(list,"\n"),pos.x,pos.y+direction*height,screen,align,0,sx,sy)
		else love.graphics.printf(self.text,pos.x,pos.y+height*direction,screen,align,0,sx,sy)
		end
		love.graphics.origin()
	end
})