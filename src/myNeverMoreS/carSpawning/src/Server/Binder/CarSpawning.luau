local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")

local CarConstants = require(ReplicatedStorage.Nevermore.Custom.car.src.Shared.CarConstants)
local BaseObject = require(ReplicatedStorage.Nevermore.Quenty.baseobject.Shared.BaseObject)
local RecolorModel = require(ReplicatedStorage.Nevermore.Custom.carSpawning.src.Server.utils.RecolorModel)
local getOwnerTag = require(ReplicatedStorage.Nevermore.Custom.carSpawning.src.Server.utils.getOwnerTag)
local randomColor = require(ReplicatedStorage.Nevermore.Custom.carSpawning.src.Server.utils.randomColor)

local carTemplate = ReplicatedStorage.Car

local spawnPromptTemplate = script.Parent.SpawnPrompt

local KIOSK_TAG = "CarSpawnKiosk"

local CarSpawning = setmetatable({}, BaseObject)
CarSpawning.__index = CarSpawning

function CarSpawning.new(kiosk: Model)
	local self = setmetatable(BaseObject.new(kiosk) :: any, CarSpawning)

	self:_setupKiosk()
	return self
end

function CarSpawning:_setupKiosk()
	local kiosk = self._obj
	local spawnLocation = kiosk:FindFirstChild("SpawnLocation")
	assert(spawnLocation, `{kiosk:GetFullName()} has no SpawnLocation part`)
	local promptPart = kiosk:FindFirstChild("Prompt")
	assert(promptPart, `{kiosk:GetFullName()} has no Prompt part`)

	-- Hide the car spawn location
	spawnLocation.Transparency = 1

	-- Create a new prompt to spawn the car
	local spawnPrompt = spawnPromptTemplate:Clone()
	spawnPrompt.Parent = promptPart

	local promptCOn = spawnPrompt.Triggered:Connect(function(player: Player)
		-- Remove any existing cars the player has spawned
		self._destroyPlayerCars(player)
		-- Spawn a new car at the spawnLocation, owned by the player
		CarSpawning._spawnCar(spawnLocation.CFrame, player)
		print("Prompt triggered")
	end)

	self._maid:GiveTask(promptCOn)
end

function CarSpawning._destroyPlayerCars(player: Player)
	local ownerTag = getOwnerTag(player)
	local cars = CollectionService:GetTagged(ownerTag)

	for _, car in cars do
		car:Destroy()
	end
end

function CarSpawning._spawnCar(location: CFrame, owner: Player?)
	local car = carTemplate:Clone()
	car:PivotTo(location)

	-- Randomly color the car
	local color = randomColor()
	RecolorModel(car, color)

	-- Set the car's owner
	if owner then
		local ownerTag = getOwnerTag(owner)
		car:AddTag(ownerTag)
		car:AddTag("Car")
		-- Since instance references can't be stored in attributes, the car owner is stored by UserId
		car:SetAttribute(CarConstants.CAR_OWNER_ATTRIBUTE, owner.UserId)
	end

	car.Parent = Workspace
end

return CarSpawning
