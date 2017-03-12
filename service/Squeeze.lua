local Squeeze = Instance:class("Squeeze",2){
    encode = function(self,super,t)
        return lemon.string.toHex(love.math.compress(lemon.table.dump(t,false),"zlib"):getString())
    end,
	decode = function(self,super,data)
		data = love.math.decompress(lemon.string.toString(data),"zlib")
		local t = loadstring("return "..data)

		if t then
			return t()
		end
	end
}
