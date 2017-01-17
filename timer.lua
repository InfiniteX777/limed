local list = {}
timer = {}
timer.__index = timer

function timer:delay(s,callback)
	active[callback] = s
end

function timer:update(dt)
	for k,v in pairs(list) do
		list[k] = list[k]-dt
		list[k] = nil
		if list[k] <= 0 then
			k()
		end
	end
end