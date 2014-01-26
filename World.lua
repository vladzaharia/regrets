
local World = {}
local Map = require("Map")
local playerAnimation = require("playerAnimation")

-- Size of players
local PSIZE = Vector(GRID_SIZE, GRID_SIZE)

-- Types of drinks
local DRINK_TYPE = {1, 2, 3, 4, 5, 6}
local DRINK_TYPE_SIZE = 6
local DRINK_FILE_NAME = {'Assets/drinks/beerBrown.png',
						 'Assets/drinks/beerGreen.png',
						 'Assets/drinks/ice.png',
						 'Assets/drinks/shotJello.png',
						 'Assets/drinks/shotTequila.png',
						 'Assets/drinks/wine.png'}

-- Types of profiles
local PROFILE_FILE_NAME = {'Assets/Profile/portraitDrunk.png'}


function World:start(width, height)
	self.width = width;
	self.height = height
	self.players = {}
	self.platforms = {}
	self.world = Map:getExampleWorld(width, height)
	self.drinks = {}

	---test making drinks
	for i=1, 3 do
		World:spawnDrink()
	end
end

function World:stop()
	self.width = nil
	self.height = nil
	self.players = nil
	self.drinks = nil
end

function World:update(dt)
	-- check for item to pickup, item currently goes into the abyss
	for id, player in pairs(self.players) do
		World:pickUp(id, self.players[id].pos)
		local p = self.players[id]
		p.pAnim:update(p.dir, p.action, dt)
	end

	--spawn drink
	local drink_count = World:tableSize(self.drinks)
	if drink_count < 3 then
		World:spawnDrink()
	end
end

function World:draw(playerPos)
	-- We want to center the player and move everything, so calculate offset
	local yCenter = math.floor(self.height / (GRID_SIZE * 2))
	local xCenter = math.floor(self.width / (GRID_SIZE * 2))
	local centerPos = Vector(xCenter, yCenter)
	local offsetPos = centerPos - playerPos
	
	-- Draw the world
	for y, row in pairs(self.world) do
		for x, item in pairs(row) do
			if item then
				if item == "W" then
					love.graphics.setColor(0, 0, 255, 255)
				end

				love.graphics.rectangle("fill", (x+offsetPos.x)*GRID_SIZE-GRID_SIZE, (y+offsetPos.y)*GRID_SIZE-GRID_SIZE, GRID_SIZE, GRID_SIZE)
			end
		end
	end

	-- Drinks
	love.graphics.reset()
	for id, drink in pairs(self.drinks) do
		local pos = drink.pos
		local drinkImage = love.graphics.newImage(DRINK_FILE_NAME[drink.type])
		love.graphics.draw(drinkImage, (pos.x+offsetPos.x)*GRID_SIZE-GRID_SIZE, (pos.y+offsetPos.y)*GRID_SIZE-GRID_SIZE)
	end

	-- Players
	--love.graphics.setColor(255, 0, 0, 255)
	for id, player in pairs(self.players) do
		local pos = player.pos
		if pos then
			--love.graphics.rectangle("fill", pos.x*GRID_SIZE-GRID_SIZE, pos.y*GRID_SIZE-GRID_SIZE, PSIZE.x, PSIZE.y)
			love.graphics.reset()
			self.players[id].pAnim:draw((pos.x+offsetPos.x)*GRID_SIZE-GRID_SIZE, (pos.y+offsetPos.y)*GRID_SIZE-GRID_SIZE)
		end
	end	

	-- Status
	love.graphics.setColor(154,205,50,255)
	love.graphics.rectangle("fill", 0, self.height - 120, self.width , 92)

	-- profile place holder
	love.graphics.reset()
	local profileImage = love.graphics.newImage(PROFILE_FILE_NAME[1])
	love.graphics.draw(profileImage, 4, self.height - 116)

end

function World:setPlayer(id, pos, dir, action)
	-- TODO: Check if colliding into something locally
	local can_move = true

	if not self.players[id] then
		self.players[id] = {leftHand = 0, rightHand = 0}
	end

	if not self.players[id].pAnim then
		self.players[id].pAnim = playerAnimation:new()
		self.players[id].pAnim:init()
	end

	for _, player in pairs(self.players) do
		if pos == player.pos then
			can_move = false
			break
		end
	end

	for y, row in pairs(self.world) do
		for x, item in pairs(row) do
			if item then
				if item == "W" then
					if pos == Vector(x,y) then
						can_move = false
						break
					end
				end
			end
		end
	end

	-- set direction and action for animations
	self.players[id].dir = dir
	self.players[id].action = action or 'stand'

	if can_move then
		self.players[id].pos = pos or self.players[id].pos or Vector(0,0)
	end

	return self.players[id].pos
end

function World:removePlayer(id)
	self.players[id] = nil
end

function World:getPlayerPosition(id)
	return self.players[id].pos
end

function World:getPlayerDirection(id)
	return self.players[id].dir
end

function World:spawnDrink()
	local freeSpace = false
	local newPos = World:randomPos()

	while not freeSpace do
		local randPos = self.world[newPos.y][newPos.x]
		if randPos == 'W' or World:collideItem(newPos) then
			newPos = World:randomPos()
		else
			freeSpace = true
		end
	end

	local drinkType = DRINK_TYPE[math.random(1, DRINK_TYPE_SIZE)]
	
	local d = {}
	d.pos = newPos
	d.type = drinkType

	table.insert(self.drinks, d)
end

function World:randomPos()
	local newX = math.random(1, World:tableSize(self.world[1])-1)
	local newY = math.random(1, World:tableSize(self.world)-1)
	return Vector(newX, newY)
end

function World:collideItem(pos)
	for id, drink in pairs(self.drinks) do
		if pos == drink.pos then
			return true
		end
	end
	return false
end

function World:pickUp(pid, ppos)
	for id, drink in pairs(self.drinks) do
		if ppos == drink.pos then
			-- put drink in inventory, doesn't exist yet
			if self.players[pid].leftHand == 0 then
				self.players[pid].leftHand = drink.type
				table.remove(self.drinks, id)
			elseif self.players[pid].rightHand == 0 then
				self.players[pid].rightHand = drink.type
				table.remove(self.drinks, id)
			end
			--two hands only, don't be greedy
			--table.remove(self.drinks, id)
		end
	end
end

function World:tableSize(tabl)
	local count = 0
	for _ in pairs(tabl) do
		count = count + 1
	end
	return count
end

return World