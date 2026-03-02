local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")

-- Use a RemoteEvent to ask the client to choose a car instead of spawning immediately.
local remoteEventsFolder = ReplicatedStorage.RemoteEvents
local chooseCarEvent = remoteEventsFolder.ChooseCar -- client listens for this to open UI and will FireServer back with the choice

local CarConstants = require(ReplicatedStorage.Nevermore.Custom.car.src.Shared.CarConstants)
local BaseObject = require(ReplicatedStorage.Nevermore.Quenty.baseobject.Shared.BaseObject)
local RecolorModel = require(ReplicatedStorage.Nevermore.Custom.carSpawning.src.Server.utils.RecolorModel)
local getOwnerTag = require(ReplicatedStorage.Nevermore.Custom.carSpawning.src.Server.utils.getOwnerTag)
local randomColor = require(ReplicatedStorage.Nevermore.Custom.carSpawning.src.Server.utils.randomColor)

local carTemplate = ReplicatedStorage.Car
local cartTemplate = ReplicatedStorage.Cart

local spawnPromptTemplate = script.Parent.SpawnPrompt

local KIOSK_TAG = "CarSpawnKiosk"

local CarSpawning = setmetatable({}, BaseObject)
CarSpawning.__index = CarSpawning

function CarSpawning.new(kiosk: Model)
	local self = setmetatable(BaseObject.new(kiosk) :: any, CarSpawning)
	self.spawnLocation = self._obj:WaitForChild("SpawnLocation")
	self.spawn_location_cframe = self.spawnLocation.CFrame
	self:_setupKiosk()
	return self
end

function CarSpawning:_setupKiosk()
	local kiosk = self._obj
	local spawnLocation = self.spawnLocation
	assert(spawnLocation, `{kiosk:GetFullName()} has no SpawnLocation part`)
	local promptPart = kiosk:FindFirstChild("Prompt")
	assert(promptPart, `{kiosk:GetFullName()} has no Prompt part`)

	-- Hide the car spawn location
	spawnLocation.Transparency = 1

	-- Create a new prompt to spawn the car
	local spawnPrompt = spawnPromptTemplate:Clone()
	spawnPrompt.Parent = promptPart

	local promptCOn = spawnPrompt.Triggered:Connect(function(player: Player)
		-- Ask client to open choose UI. Include spawn location so the client can show context if needed.
		chooseCarEvent:FireClient(player, { obj = self._obj, spawnLocation = spawnLocation.CFrame })

		print("Prompt triggered: opened ChooseCar UI for", player.Name)
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

-- Make spawn public and accept optional choice data (currently ignored)
type choiceData = {
	choiceName: string,
}

local ref = {
	["Car"] = carTemplate,
	["Cart"] = cartTemplate,
}

function CarSpawning:SpawnCar(owner: Player?, choiceData: choiceData)
	-- Remove any existing cars the player has spawned
	self._destroyPlayerCars(owner)
	local template = ref[choiceData.choiceName]:Clone()
	if not template then
		print("invalid choiceName ", choiceData.choiceName)
	end
	template:PivotTo(self.spawn_location_cframe)

	-- Randomly color the car
	local color = randomColor()
	RecolorModel(template, color)

	-- Set the car's owner
	if owner then
		local ownerTag = getOwnerTag(owner)
		template:AddTag(ownerTag)
		template:AddTag("Car")
		-- Since instance references can't be stored in attributes, the car owner is stored by UserId
		template:SetAttribute(CarConstants.CAR_OWNER_ATTRIBUTE, owner.UserId)
	end

	template.Parent = Workspace
end

-- Backwards-compatible alias
CarSpawning._spawnCar = CarSpawning.SpawnCar

return CarSpawning
