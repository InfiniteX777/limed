--[[ lemon ]
Description: Commonly used functions.

Functions:
	Number clamp( Sets the value no greater than or less than the other two values.
		Number a - Least possible value.
		Number b - Greatest possible value.
		Number v - The value being tested.
	) - Returns the 'clamped' value.
]]
lemon = {}
lemon.__index = lemon

function lemon.clamp(a,b,v)
	return math.max(a or 0,math.min(v or 0,b or 0))
end