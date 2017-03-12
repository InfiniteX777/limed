local ceil,floor,rad = math.ceil,math.floor,math.rad
local insert = table.insert

local cache = {
	Image = {},
	Font = {},
	Map = {}
}
local mapIndex = {
	static = true,
	restitution = true,
	friction = true,
	sensor = true,
	segments = true
}

local function apply(rigid,...)
	for _,v in pairs({...}) do
		rigid:applyFixture(function(fixture)
			if v.restitution ~= nil then
				fixture:setRestitution(v.restitution)
			end
			if v.friction ~= nil then
				fixture:setFriction(v.friction)
			end
			if v.sensor ~= nil then
				fixture:setSensor(v.sensor)
			end
		end)
	end
end

local ContentService = Instance:class("ContentService",2){
	fontAlignment = {
		topleft = {0,0,"left"},
		middleleft = {0,0.5,"left"},
		bottomleft = {0,1,"left"},
		topcenter = {0.5,0,"center"},
		middlecenter = {0.5,0.5,"center"},
		bottomcenter = {0.5,1,"center"},
		topright = {1,0,"right"},
		middleright = {1,0.5,"right"},
		bottomright = {1,1,"right"}
	},
	loadItem = function(self,super,id)
		local properties = Instance:service("Squeeze"):decode(id)

		if not properties then return end
		-- Corrupted ID

		local stats = Instance:service("Statistics")

		return self:new("Item",function(self)
			self.get = function(self,k)
				if properties[k] then
					if type(properties[k]) == "function" then
						return function(...)
							return properties[k](self,...)
						end
					else return properties[k]
					end
				end

				return stats.item[k]
			end
			self.id = function(self)
				return id
			end
			self.iterate = function(self)
				return pairs(properties)
			end
			self.equal = function(self,item)
				return self:id() == item:id() and self:name() == item:name()
			end
		end)
	end,
	loadImage = function(self,super,source)
		if not cache.Image[source] then
			cache.Image[source] = self:new("Image",function(self)
				self.image = love.graphics.newImage(source)
				self.width = self.image:getWidth()
				self.height = self.image:getHeight()
			end)
		end

		return cache.Image[source]
	end,
	loadFont = function(self,super,source,size)
		local source = source or "default"
		local size = size or 12
		local t = lemon.table.init(cache,"Font",size)
		if not t[source] then
			if source == "default" then
				t[source] = self:new("FontAsset",function(self)
					self.font = love.graphics.newFont(size)
				end)
			else t[source] = self:new("FontAsset",function(self)
					self.font = love.graphics.newFont(source,size)
				end)
			end
		end

		return t[source]
	end,
	resetFont = function(self,super,size)
		love.graphics.setFont(self:loadFont().font)
	end,
	loadMap = function(self,super,source)
		local tiled = cache.Map[source] or require(source)
		tiled.tiles = {}
		local map = self:new("Map")

		local w,h = tiled.tilewidth,tiled.tileheight

		-- World Initialization
		map.world:setGravity(0,(tiled.properties.gravity or 0)*love.physics:getMeter())

		-- Generate Tileset
		if not cache.Map[source] then
			for _,v in pairs(tiled.tilesets) do
				local n = v.firstgid
				local image = self:loadImage("assets/"..v.image:gsub("%.%./",""))
				local w,h = v.tilewidth,v.tileheight
				local iw,ih = v.imagewidth,v.imageheight
				local s,m = v.spacing,v.margin
				local empty = {}
				for y=0,ceil(((ih-m)/(h+s)))-1 do
					for x=0,ceil(((iw-m)/(w+s)))-1 do
						if not tiled.tiles[n] then
							tiled.tiles[n] = {
								image = image:quad(m+x*(w+s),m+y*(h+s),w,h),
								properties = empty,
								set = v
							}
						end
						n = n+1
					end
				end
				local l = {}
				for _,tile in pairs(v.tiles) do
					local t = tiled.tiles[tile.id+1]

					-- Animation
					if tile.animation then
						local sprite = image:sprite(w,h,0,0,m,m,s,s)
						for _,v in pairs(tile.animation) do
							local d = tiled.tiles[v.tileid+1].image
							insert(sprite.sheet,{
								x = d.x,
								y = d.y,
								delay = v.duration/1000
							})
						end
						l[tile.id+1] = sprite
						sprite:play()
					end

					-- Properties
					t.properties = tile.properties or empty
				end
				for k,v in pairs(l) do
					tiled.tiles[k].image = v
				end
			end
		end

		-- Render
		for index,layer in pairs(tiled.layers) do
			local ox,oy = layer.offsetx,layer.offsety
			local lType = layer.type

			if lType == "imagelayer" then
				local x,y = ox,oy
				local image = self:loadImage("assets/"..layer.image:gsub("%.%./",""))
				image.color.a = layer.opacity*255

				local frame = Instance:new("Frame")
				frame.image = image
				frame.offset:set(x,y,image.width,image.height)
				frame.fillColor.a = 0
				frame.lineColor.a = 0
				Color:new(255,255,255,255)

				map:add(frame,index)
			else for k,v in pairs(lType == "tilelayer" and layer.data or layer.objects) do
					local x,y = ox,oy
					local static = true
					local rigid
					local object = lType == "tilelayer" and tiled.tiles[v] or lType == "objectgroup" and v

					if object then
						if object.properties.static ~= nil then
							static = object.properties.static
						elseif layer.properties.static ~= nil then
							static = layer.properties.static
						end
					end

					if lType == "tilelayer" and v > 0 then
						k = k-1
						x,y = x+k%layer.width+0.5,y+floor(k/layer.height)+0.5

						rigid = map:rigid(index,map:rectangle(
							static,
							x*w+layer.offsetx,
							y*h+layer.offsety,
							w,
							h
						),object.image)

						local set = object.set
						rigid.imageOffset = Vector2:new(
							set.tileoffset.x+(set.tilewidth-w)/2,
							set.tileoffset.y-(set.tileheight-h)/2
						)
					elseif lType == "objectgroup" then
						x,y = x+w/2+object.x,y+h/2+object.y

						if object.gid or object.shape == "rectangle" or object.shape == "ellipse" then
							local a,b,r = object.width,object.height,rad(object.rotation)
							local p = Vector2:new(x,y):rotate(Vector2:new(x-a/2,y-b/2),r)

							if object.gid then
								local tile = tiled.tiles[object.gid]
								local set = tile.set
								rigid = map:rigid(index,map:rectangle(
									static,
									p.x+set.tileoffset.x+(set.tilewidth-w)/2,
									p.y+set.tileoffset.y-(set.tileheight-h)/2-h,
									object.width,
									object.height
								),tile.image)
							elseif object.shape == "rectangle" then
								rigid = map:rigid(index,map:rectangle(
									static,
									p.x+w,
									p.y+h,
									object.width,
									object.height
								))
							else rigid = map:rigid(index,map:ellipse(
									static,
									p.x+(a-w)/2,
									p.y+(b-h)/2,
									a/2,
									b/2,
									object.properties.segments
								))
							end

						elseif object.shape == "polyline" or object.shape == "polygon" then
							if type(object[object.shape][1]) == "table" then
								local t = {}
								for k,v in pairs(object[object.shape]) do
									insert(t,v.x)
									insert(t,v.y)
								end
								object[object.shape] = t
							end

							if object.shape == "polyline" then
								rigid = map:rigid(index,map:polyline(
									static,
									x-w/2,
									y-h/2,
									object.polyline
								))
							else rigid = map:rigid(index,map:polygon(
									static,
									x-w/2,
									y-h/2,
									object.polygon
								))
							end
						end

						rigid.body:setAngle(rad(object.rotation))
					end

					if rigid then
						apply(rigid,layer.properties,object.properties)

						-- Apply Layer Properties
						for k,v in pairs(layer.properties) do
							if not mapIndex[k] then
								rigid[k] = v
							end
						end

						-- Apply Object-Specific Properties (Overwrites layer properties)
						for k,v in pairs(object.properties) do
							if not mapIndex[k] then
								rigid[k] = v
							end
						end
					end
				end
			end
		end

		return map
	end
}
