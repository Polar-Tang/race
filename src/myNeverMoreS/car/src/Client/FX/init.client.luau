local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ControllerBaseClient = require(ReplicatedStorage.Nevermore.Custom.car.src.Client.Controllers.ControllerBaseClient)
local ControllersTypeClient =
	require(ReplicatedStorage.Nevermore.Custom.car.src.Client.Controllers.ControllersTypeClient)
local CarConstants = require(ReplicatedStorage.Nevermore.Custom.car.src.Shared.CarConstants)
local Audio = require(script.Audio)
local Particles = require(script.Particles)
local Haptics = require(script.Haptics)

local COLLISION_UPDATE_INTERVAL = 0.1 -- Time interval to calculate average change over
local COLLISION_THRESHOLD = 400 -- Amount of average change that must be passed to play a collision sound
local COLLISION_VOLUME_FACTOR = 1 / 800 -- Amount to adjust volume based on the average change

local FX = setmetatable({}, ControllerBaseClient)
FX.__index = FX
FX.ClassName = "FX"

function FX.new(config: ControllersTypeClient.ControllConstructor)
	local self = setmetatable(ControllerBaseClient.new(config), FX) :: ControllersTypeClient.ControllerBase

	self._totalSpeedChange = 0
	self._lastSpeed = self.chassis.AssemblyLinearVelocity.Magnitude
	self._lastCollisionUpdate = os.clock()

	return self
end

function FX._onFXChanged(self: ControllersTypeClient.FX)
	if self.driverSeat.Occupant then
		Audio.startupEngine()
		local driver = Players:GetPlayerFromCharacter(self.driverSeat.Occupant.Parent)
		if driver == Players.LocalPlayer then
			Haptics.enable()
		end
	else
		Audio.shutdownEngine()
		Haptics.disable()
	end
end

function FX._onNitroEnabledChanged(self: ControllersTypeClient.FX)
	local isNitroEnabled = self.engine:GetAttribute(CarConstants.NITRO_ENABLED_ATTRIBUTE)
	if isNitroEnabled then
		Audio.startNitro()
		Particles.startNitro()
		Haptics.startNitro()
	else
		Audio.stopNitro()
		Particles.stopNitro()
		Haptics.stopNitro()
	end
end

function FX._onHeartbeat(self: ControllersTypeClient.FX, _deltaTime: number)
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
		Audio.playCollisionSound(strength)
		Haptics.playCollisionHaptic(strength)
	end

	self._totalSpeedChange = 0
end

function FX.Init(self: ControllersTypeClient.FX)
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
