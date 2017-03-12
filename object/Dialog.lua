local floor,min,max = math.floor,math.min,math.max
local graphics = Instance:service"GraphicsInterface"
local content = Instance:service"ContentService"

local Dialog = Instance:class("Dialog",3){
    map = nil,
    ui = nil,
    arrow = nil,
    rigid = nil,
    lifespan = nil,
    distance = 30,
    new = function(self,super)
        self.font = content:loadFont()
        self.lifespan = 2
    end,
    update = function(self,super,dt)
		if self.ui then
			self.ui:update(dt)
		end

        if self.lifespan then
            self.lifespan = self.lifespan-dt
			if self.lifespan+0.5 <= 0 then
				self:destroy()
			end
        end
    end,
    draw = function(self,super,x,y,angle,sx,sy,...)
        local ui,arrow,rigid = self.ui,self.arrow,self.rigid

        if ui and rigid then
            local angle,sx,sy = angle or 0,sx or 1,sy or 1
            local bx,by = rigid.body:getPosition()
            local edge = ui.borderEdgeSize
            local size = ui.offset.size
            local fade = self.lifespan and self.lifespan+0.5 <= 0.5



            love.graphics.push()
            love.graphics.rotate(angle)
            love.graphics.translate(x,y)
            love.graphics.scale(sx,sy)
            love.graphics.translate(bx-size.x/2,by-size.y-self.distance)

            if fade then
                graphics:pushColor(255,255,255,max(0,self.lifespan+0.5)*255*2)
            end

            ui:draw(0,0)

            if fade then
                graphics:popColor()
            end

            graphics:popColor()
            love.graphics.pop()
        end
    end,
    destroy = function(self,super)
        for _,v in pairs({"ui","arrow"}) do
            if self[v] then
                self[v]:destroy()
            end
        end

        self.map:rem(self)
        super.destroy(self)
    end
}
