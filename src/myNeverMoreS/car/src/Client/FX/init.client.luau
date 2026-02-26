local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ControllerBaseClient = require(ReplicatedStorage.Nevermore.Custom.car.src.Client.Controllers.ControllerBaseClient)
local ControllersTypeClient =
	require(ReplicatedStorage.Nevermore.Custom.car.src.Client.Controllers.ControllersTypeClient)
local BaseService = require(ReplicatedStorage.Nevermore.Custom.car.src.Client.utils.BaseService)
local CarConstants = require(ReplicatedStorage.Nevermore.Custom.car.src.Shared.CarConstants)

local COLLISION_UPDATE_INTERVAL = 0.1 -- Time interval to calculate average change over
local COLLISION_THRESHOLD = 400 -- Amount of average change that must be passed to play a collision sound
local COLLISION_VOLUME_FACTOR = 1 / 800 -- Amount to adjust volume based on the average change

type FX = ControllersTypeClient.FX
local FX = setmetatable({}, ControllerBaseClient)
FX.__index = FX
FX.ClassName = "FX"

function FX.new(config: ControllersTypeClient.ControllConstructor)
	local self = setmetatable(BaseService.new(config) :: any, FX) :: FX

	self._totalSpeedChange = 0
	self._lastSpeed = self.chassis.AssemblyLinearVelocity.Magnitude
	self._lastCollisionUpdate = os.clock()

	self:_initControllers(script.Parent.Controllers)

	return self
end

function FX._onFXChanged(self: FX)
	if self.driverSeat.Occupant then
		self._controllers["Audio"]:StartupEngine()
		local driver = Players:GetPlayerFromCharacter(self.driverSeat.Occupant.Parent)
		if driver == Players.LocalPlayer then
			self._controllers["Haptics"]:Enable()
		end
	else
		self._controllers["Audio"]:ShutdownEngine()
		self._controllers["Haptics"]:Disable()
	end
end

function FX._onNitroEnabledChanged(self: FX)
	local isNitroEnabled = self.engine:GetAttribute(CarConstants.NITRO_ENABLED_ATTRIBUTE)
	if isNitroEnabled then
		self._controllers["Audio"]:StartNitro()
		self._controllers["Particles"]:StartNitro()
		self._controllers["Haptics"]:StartNitro()
	else
		self._controllers["Audio"]:StopNitro()
		self._controllers["Particles"]:StopNitro()
		self._controllers["Haptics"]:StopNitro()
	end
end

function FX._onHeartbeat(self: FX, _deltaTime: number)
	-- Play collision effects when the speed of the car changes abruptly.
	-- This is more consistent than listening to .Touched,

	-- Calculate the change in the car's speed and add it to self._totalSpeedChange
	local speed = self.chassis.AssemblyLinearVelocity.Magnitude
	local change = math.abs(speed - self._lastSpeed)
	self._lastSpeed = speed
	self._totalSpeedChange += change

	local elapsed = os.clock() - self._lastCollisionUpdate
	if elapsed < COLLISION_UPDATE_INTERVAL then
		return
	end
	self._lastCollisionUpdate = os.clock()

	-- Calculate the average change in speed over the update interval
	local averageChangeOverInterval = self._totalSpeedChange / elapsed
	if averageChangeOverInterval > COLLISION_THRESHOLD then
		-- If the change is higher than the threshold, play collision effects
		local strength = averageChangeOverInterval * COLLISION_VOLUME_FACTOR
		self._controllers["Audio"]:PlayCollisionSound(strength)
		self._controllers["Haptics"]:PlayCollisionHaptic(strength)
	end

	self._totalSpeedChange = 0
end

function FX.Init(self: FX)
	self.driverSeat:GetPropertyChangedSignal("Occupant"):Connect(function(...)
		self:_onFXChanged(...)
	end)
	self.engine:GetAttributeChangedSignal(CarConstants.NITRO_ENABLED_ATTRIBUTE):Connect(function(...)
		self:_onNitroEnabledChanged(...)
	end)

	self:_onFXChanged()
	self:_onNitroEnabledChanged()
	RunService.Heartbeat:Connect(function(a0: number)
		self:_onHeartbeat(a0)
	end)
end

return FX
