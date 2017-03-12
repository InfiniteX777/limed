local Tremor = Instance:class("Tremor",4){
    source = nil,
    magnitude = 0,
    intensity = 4,
    radius = 64,
    threshold = 0.1,
    update = function(self,super,dt)
        local intensity = self.intensity

        if intensity > 0 then
            self.magnitude = self.magnitude*(1-1/intensity)
        end
    end
}
