local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

--== UTILS==--
local ControllersTypeClient =
	require(ReplicatedStorage.Nevermore.Custom.car.src.Client.ControllersUtils.ControllersTypeClient)
local BaseService = require(ReplicatedStorage.Nevermore.Custom.car.src.Client.utils.BaseService)
local CarConstants = require(ReplicatedStorage.Nevermore.Custom.car.src.Shared.CarConstants)
local Controller = require(ReplicatedStorage.Nevermore.Custom.car.src.Shared.Controller)
local Maid = require(ReplicatedStorage.Nevermore.Quenty.loader.Maid)

local Controllers: ControllersTypeClient.CarControllers = {
	["CameraClass"] = require(script.Parent.Parent.Controllers.Camera),
	["ClassInput"] = require(script.Parent.Parent.Controllers.Input),
	["Speedometer"] = require(script.Parent.Parent.Controllers.Speedometer),
	["FX"] = require(script.Parent.Parent.Controllers.FX),
}

local setNitroEnabledRemote = ReplicatedStorage.RemoteEvents.SetNitroEnabled

local setJumpingEnabled = require(script.Parent.utils.setJumpingEnabled)

local maid = Maid.new()
local destructionHandlerTemplate = script.Parent.utils.DestructionHandler
local player = Players.LocalPlayer

local CarClient = setmetatable({}, BaseService)
CarClient.__index = CarClient
CarClient.ClassName = "CarClient"

function CarClient.new(car: Model)
	local config: ControllersTypeClient.ControllConstructor = {
		car = car,
	}
	local self = setmetatable(BaseService.new(config) :: any, CarClient)

	self._totalSpeedChange = 0
	self._lastSpeed = self.chassis.AssemblyLinearVelocity.Magnitude
	self._lastCollisionUpdate = os.clock()

	-- self._driverSeat = car.DriverSeat :: Seat
	-- self._engine = car.Engine :: Folder

	self._animations = car:FindFirstChild("Animations") :: Folder

	self._driveAnimation = self._animations.DriveAnimation :: Animation

	self._isControlling = false
	self._driveAnimationTrack = nil

	return self
end

function CarClient.Init(self: ControllersTypeClient.CarClient)
	local config: ControllersTypeClient.ControllConstructor = {
		car = self.car,
	}
	self._DriverController = Controller.new(config)
	self._DriverController:initialize()
	self:_initControllers(Controllers)
	self._controllers["FX"]:Init()
	self:SetupDestructionHandler()

	self._maid:GiveTask(self.driverSeat:GetPropertyChangedSignal("Occupant"):Connect(function()
		self:OnOccupantChanged()
	end))
end

-- Enable the client modules and Controller update loop
function CarClient.StartControlling(self: ControllersTypeClient.CarClient)
	if self._isControlling then
		return
	end
	self._isControlling = true

	-- Stop the player from jumping out the seat since a separate key is bound to exit the car.
	local character = player.Character
	if character then
		setJumpingEnabled(character, false)

		-- Play the driving animation
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			local animator = humanoid:FindFirstChildOfClass("Animator")
			if animator then
				self._driveAnimationTrack = animator:LoadAnimation(self._driveAnimation)
				if self._driveAnimationTrack then
					self._driveAnimationTrack:Play()
				end
			end
		end
	end

	-- Connect the Controller's update function to RunService.Stepped.
	-- Stepped is used here since it fires prior to the physics simulation, and the controller
	-- updates the physics constraints on the car.
	maid:GiveTask(RunService.Stepped:Connect(function(_, deltaTime: number)
		self._DriverController:update(deltaTime)
	end))

	-- Enable replication for the nitro audio and VFX
	maid:GiveTask(self.engine:GetAttributeChangedSignal(CarConstants.NITRO_ENABLED_ATTRIBUTE):Connect(function()
		local isNitroEnabled = self.engine:GetAttribute(CarConstants.NITRO_ENABLED_ATTRIBUTE)
		setNitroEnabledRemote:FireServer(self.car, isNitroEnabled)
	end))

	-- Enable the client modules
	self._controllers["CameraClass"]:Enable()
	self._controllers["ClassInput"]:Enable()
	self._controllers["Speedometer"]:Enable()
end

-- Disable the client modules and Controller update loop
function CarClient.StopControlling(self: ControllersTypeClient.CarClient)
	if not self._isControlling then
		return
	end
	self._isControlling = false

	-- Disable the client modules
	self._controllers["CameraClass"]:Disable()
	self._controllers["ClassInput"]:Disable()
	self._controllers["Speedometer"]:Disable()

	-- Disconnect event connections
	maid:DoCleaning()

	-- Reset the car Controller. If the car has been destroyed (i.e. is not parented anywhere in the DataModel) this can be skipped.
	if self.car:IsDescendantOf(game) then
		self._DriverController:reset()
	end

	-- Reenable jumping for the player
	local character = player.Character
	if character then
		setJumpingEnabled(character, true)
	end

	-- Stop the driving animation
	if self._driveAnimationTrack then
		self._driveAnimationTrack:Stop()
		self._driveAnimationTrack = nil
	end
end

-- Call startControlling() or stopControlling() if the player enters or exits the seat
function CarClient.OnOccupantChanged(self: ControllersTypeClient.CarClient)
	local isOccupiedByLocalPlayer = false

	local humanoid = self.driverSeat.Occupant
	if humanoid then
		local character = humanoid.Parent
		local playerInSeat = Players:GetPlayerFromCharacter(character)
		if playerInSeat == player then
			isOccupiedByLocalPlayer = true
		end
	end

	if isOccupiedByLocalPlayer then
		self:StartControlling()
	else
		self:StopControlling()
	end
end

-- When using Deferred signal mode: since this script is parented to the car, destroying the car will clean up
-- all connections (including .Destroying) before they can actually execute.
-- To avoid this, we'll use a slightly hacky solution and clone a listener script into PlayerScripts.
-- This script will continue running after the car is destroyed and allow us to properly clean up when the car is destroyed.
function CarClient.SetupDestructionHandler(self: ControllersTypeClient.CarClient)
	local destructionHandler = destructionHandlerTemplate:Clone()
	destructionHandler.Parent = player.PlayerScripts
	destructionHandler.Enabled = true

	-- Defer firing the BindableEvent so the script is able to initialize first
	task.defer(function()
		destructionHandler.BindToCar:Fire(self.car, function()
			self:StopControlling()
		end)
	end)
end

return CarClient
