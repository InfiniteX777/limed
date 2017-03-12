local insert,remove = table.insert,table.remove

SkipList = Instance:api{
	new = function(self)
		self.list = {}
		self.size = 0
		self.length = 0
	end,
	insert = function(self,index,value,pos)
		assert(type(index == "number") and index >= 0,"Invalid index.")

		-- 1st Dimension

		local list = self.list

		if not list[index] then
			list[index] = {}
		end

		if self.size < index then
			self.size = index
		end

		local layer = list[index]

		-- 2nd Dimension

		self.length = self.length+1

		if pos and pos > #layer then
			pos = nil
		end

		if pos then
			insert(layer,pos,value)
		else insert(layer,value)
		end
	end,
	remove = function(self,index,value)
		assert(type(index == "number") and index >= 0, "Invalid index.")

		local list = self.list
		local layer = list[index]

		if not layer then return end

		for k,v in pairs(layer) do
			if v == value then
				self.length = self.length-1
				remove(layer,k)
				break
			end
		end

		if #layer == 0 then
			list[index] = nil

			if self.size == index then
				for i=index-1,0,-1 do
					if list[i] then
						self.size = i
						break
					end
				end
			end
		end
	end,
	ipairs = function(self,a,b)
		local list = self.list
		local size = self.size

		local layer,node = 0,0

		return function()
			node = node+1

			while layer <= size and (not list[layer] or node > #list[layer]) do
				layer = layer+1
				node = 1
			end

			return list[layer] and layer,list[layer] and list[layer][node]
		end
	end
}
