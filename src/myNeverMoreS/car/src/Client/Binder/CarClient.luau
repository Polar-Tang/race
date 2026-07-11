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

	-- Connections that only live while the local player is driving. Owned by
	-- self._maid so Destroy() also cleans an active session.
	self._controlMaid = Maid.new()
	self._maid:GiveTask(self._controlMaid)

	return self
end

function CarClient.Init(self: ControllersTypeClient.CarClient)
	repeat
		task.wait()
	until self.engine:GetAttribute(CarConstants.ENGINE_SPEED_ATTRIBUTE)

	local config: ControllersTypeClient.ControllConstructor = {
		car = self.car,
	}
	self._DriverController = Controller.new(config)
	self._DriverController:initialize()
	self._maid:GiveTask(self._DriverController)
	-- _initControllers already maid-tracks every controller and calls Init on it
	self:_initControllers(Controllers)

	self._maid:GiveTask(self.driverSeat:GetPropertyChangedSignal("Occupant"):Connect(function()
		self:OnOccupantChanged()
	end))

	-- Top of the client hierarchy: destroying cascades through self._maid to the
	-- DriverController, every controller (and their own maids/sub-controllers).
	self._maid:GiveTask(config.car.AncestryChanged:Connect(function(_, parent)
		if not parent then
			self:Destroy()
		end
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
	self._controlMaid:GiveTask(RunService.Stepped:Connect(function(_, deltaTime: number)
		self._DriverController:update(deltaTime)
	end))

	-- Enable replication for the nitro audio and VFX
	self._controlMaid:GiveTask(self.engine:GetAttributeChangedSignal(CarConstants.NITRO_ENABLED_ATTRIBUTE):Connect(function()
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

	-- Disconnect the driving-session connections only. The controllers are NOT
	-- destroyed here: they must survive to be Enabled again when the player
	-- re-enters the seat; they die with the CarClient (self._maid) in Destroy().
	self._controlMaid:DoCleaning()
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

-- Polymorphic Destroy: end an active driving session first (restores camera,
-- touch controls, jumping), then let the base class clean self._maid, which
-- cascades Destroy to the DriverController and every controller under it.
function CarClient.Destroy(self: ControllersTypeClient.CarClient)
	self:StopControlling()
	BaseService.Destroy(self)
end

return CarClient
