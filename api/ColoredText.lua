local max = math.max
local insert = table.insert

local cache = {
	FFFFFF = {255,255,255}
}

local function format(text,colored,abs)
	local abs = abs or ""
	local colored = colored or {}
	local color = "FFFFFF"
	local a,b,match

	repeat
		a,b,match = text:find("#(%x%x%x%x%x%x)%s")

		if a then
			if a > 1 then
				local v = text:sub(1,a-1)
				abs = abs..v

				insert(colored,cache[color])
				insert(colored,v)
			end

			color = match
			if not cache[color] then
				cache[color] = {
					tonumber(color:sub(1,2),16),
					tonumber(color:sub(3,4),16),
					tonumber(color:sub(5,6),16)
				}
			end

			text = text:sub(b+1)
		elseif text:len() > 0 then
			abs = abs..text

			insert(colored,cache[color])
			insert(colored,text)
		end
	until not a

	return colored,abs
end

local function hex(color)
	return string.format("%02X%02X%02X",unpack(color))
end

ColoredText = Instance:api{
	new = function(self,text)
		self:set(text)
	end,
	set = function(self,text)
		local text = text or ""
		self.text = text
		self.colored,self.abs = format(text)
	end,
	copy = function(self,text,colored,abs)
		self.text,self.colored,self.abs = text,colored,abs
	end,
	insert = function(self,text)
		local text = text or ""
		self.text = self.text..text
		_,self.abs = format(text,self.colored,abs)
	end,
	sub = function(self,a,b)
		local len = self.abs:len()

		if b and a > b or a > len then return "" end -- Invalid argument.

		local colored = self.colored
		local a,b,i = max(1,a),b or len,1
		local n = ""

		while b > 0 and colored[i] do
			local c = a
			local text = colored[i+1]

			if a <= text:len() then
				text = text:sub(a,b)
				b = b-text:len()
				a = 1

				n = n.."#"..hex(colored[i]).." "..text
			else a = a-text:len()
			end

			b = b-(c-a)
			i = i+2
		end

		return n
	end,
	coloredSub = function(self,a,b)
		local len = self.abs:len()

		if b and a > b or a > len then return {} end -- Invalid argument.

		local colored = self.colored
		local a,b,i = max(1,a),b or len,1
		local n = {}

		while b > 0 and colored[i] do
			local c = a
			local text = colored[i+1]

			if a <= text:len() then
				text = text:sub(a,b)
				b = b-text:len()
				a = 1

				insert(n,colored[i])
				insert(n,text)
			else a = a-text:len()
			end

			b = b-(c-a)
			i = i+2
		end

		return n
	end,
	cut = function(self,a,b)
		local len = self.abs:len()
		local n = ColoredText:new()

		if b and a > b or a > len then return n end -- Invalid argument.

		local colored = self.colored
		local a,b,i = max(1,a),b or len,1
		local nText,nColored,nAbs = "",{},""

		while b > 0 and colored[i] do
			local c = a
			local text = colored[i+1]

			if a <= text:len() then
				text = text:sub(a,b)
				b = b-text:len()
				a = 1

				nText = nText.."#"..hex(colored[i]).." "..text
				nAbs = nAbs..text
				insert(nColored,colored[i])
				insert(nColored,text)
			else a = a-text:len()
			end

			b = b-(c-a)
			i = i+2
		end

		n:copy(nText,nColored,nAbs)

		return n
	end
}
