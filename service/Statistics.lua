local abs = math.abs

local function set(a,b,c,d)
    return function(self,super,v)
        local v = v or 1
        local m,f = v < 0 and c or a,v < 0 and d or b
        local mul = v*f/(1+f*abs(v))

        return mul*m
    end
end

local stat = Instance:class("Statistics",2){
	-- Item Base Stats
	item = {
		-- Generic
		name = "Generic Item",
		description = "This is a generic item.",
		type = "generic",
		icon = nil,
		stackSize = 64,

		-- Armor
		strength = 0,
		health = 0,
		healthRegen = 0,

		agility = 0,
		armor = 0,
		physicalDamage = 0,

		intelligence = 0,
		mana = 0,
		manaRegen = 0,
		magicalDamage = 0,

		resist = 0,
		moveSpeed = 0,

		-- Weapon
		attackRange = 100,
		melee = true,
		missile = nil,
		missileSpeed = 1000,

		-- Acessory
		activeCallback = nil
	},

	-- Player Stats
    -- Natural Bonuses
    base = {
        health = 200,
        healthRegen = 0.5,

        armor = 1,
        physicalDamage = 10,

        mana = 200,
        manaRegen = 0.5,
        magicalDamage = 20,

        resist = 10,
        moveSpeed = 300
    },

    -- Stats (Each point allocated changes the following aspects.)
    -- Strength
    health = set(800,1/30,100,1/20),
    healthRegen = set(10,1/40,0.5,1/40),

    -- Agility
    armor = set(1,1/40,1,1/60),
    physicalDamage = set(60,1/20,10,1/20),

    -- Intelligence
    mana = set(800,1/40,100,1/20),
    manaRegen = set(10,1/60,0.5,1/40),
    magicalDamage = set(100,1/20,20,1/20),

    -- Synthetic Bonuses (Only increased by items and buffs.)
    resist = set(1,1/40,1,1/60),
    moveSpeed = set(212,1/40,200,1/20)
}
