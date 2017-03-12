--[[ Item Types ]
	generic - Cannot be equipped nor activated/consumed.
	armor - Equippable armor.
	weapon - Equippable weapon.
	accessory - Optional active/consume component. Equippable accessory.
]]

local Item = Instance:class("Item",3){
	stack = 1
}
