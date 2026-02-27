local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local ControllerBaseClient = require(ReplicatedStorage.Nevermore.Custom.car.src.Client.ControllersUtils.ControllerBaseClient)
local ControllersTypeClient = require(ReplicatedStorage.Nevermore.Custom.car.src.Client.ControllersUtils.ControllersTypeClient)
local CarConstants = require(ReplicatedStorage.Nevermore.Custom.car.src.Shared.CarConstants)
local getAverageWheelSlip = require(script.Parent.Parent.utils.getAverageWheelSlip)
local getSuspensionLength = require(script.Parent.Parent.utils.getSuspensionLength)
local playRandomPlayer = require(script.Parent.Parent.utils.playRandomPlayer)

local ENGINE_VOLUME = 0.22 -- Default engine volume
local ENGINE_PLAYBACK_SPEED = 1 -- Default engine playback speed
local ENGINE_VOLUME_STARTUP_TWEEN_TIME = 0.3 -- Time it takes for the engine loop to fade in
local ENGINE_PLAYBACK_SPEED_FACTOR = 1 / 80 -- Amount to adjust playback speed based on the car's speed
local TIRES_VOLUME = 0.25 -- Default tires volume
local TIRES_VOLUME_FACTOR = 1 / 100 -- Amount to adjust volume based on the speed of the car
local TIRES_SLIDING_VOLUME = 0.6 -- Default tires sliding volume
local TIRES_SLIDING_VOLUME_FACTOR = 1 / 80 -- Amount to adjust volume based on the amount the car is sliding

local SUSPENSION_UPDATE_INTERVAL = 0.1 -- Time interval to calculate average change over
local SUSPENSION_THRESHOLD = 15 -- Amount of average change that must be passed to play a suspension sound
local SUSPENSION_VOLUME_FACTOR = 1 / 50 -- Amount to adjust volume based on the average change

local COLLISION_VOLUME_FACTOR = 1 / 800 -- Amount to adjust volume based on the average change

local Audio = setmetatable({}, ControllerBaseClient)
Audio.__index = Audio
Audio.ClassName = "Audio"

function Audio.new(config: ControllersTypeClient.ControllConstructor)
	local self = setmetatable(ControllerBaseClient.new(config), Audio) :: ControllersTypeClient.ControllerBase

	-- declare audio player
	do
		self._audioPlayers = self.chassis.Audio.Players
		self._engineStartup = self._audioPlayers.Engine.EngineStartupPlayer
		self._engineShutdown = self._audioPlayers.Engine.EngineShutdownPlayer
		self._engineLoop = self._audioPlayers.Engine.EngineLoopPlayer
		self._tiresLoop = self._audioPlayers.Tires.TiresLoopPlayer
		self._tiresSlidingLoop = self._audioPlayers.Tires.TiresSlidingLoopPlayer
		self._nitroStart = self._audioPlayers.Nitro.NitroStartPlayer
		self._nitroStop = self._audioPlayers.Nitro.NitroStopPlayer
		self._nitroLoop = self._audioPlayers.Nitro.NitroLoopPlayer
		self._suspension = self._audioPlayers.Suspension:GetChildren()
		self._collision = self._audioPlayers.Collision:GetChildren()
	end

	self._engineRunning = false
	self._nitroEnabled = false

	self._totalSuspensionChange = 0
	self._lastSuspensionLength = getSuspensionLength(self.car)
	self._lastSuspensionUpdate = os.clock()

	return self
end

-- Play suspension rattle sounds when the car's total suspension length changes abruptly.
-- To keep things simple, the car's suspension is treated as a single long spring.
function Audio._updateSuspensionSounds(self: ControllersTypeClient.Audio)
	local suspensionLength = getSuspensionLength(self.car)
	local change = math.abs(suspensionLength - self._lastSuspensionLength)
	self._lastSuspensionLength = suspensionLength
	self._totalSuspensionChange += change

	local elapsed = os.clock() - self._lastSuspensionUpdate
	if elapsed < SUSPENSION_UPDATE_INTERVAL then
		return
	end
	self._lastSuspensionUpdate = os.clock()

	-- Calculate the average change in length over the update interval
	local averageChangeOverInterval = self._totalSuspensionChange / elapsed
	if averageChangeOverInterval > SUSPENSION_THRESHOLD then
		-- If the change is higher than the threshold, play a random suspension sound
		local volume = averageChangeOverInterval * SUSPENSION_VOLUME_FACTOR
		playRandomPlayer(self._suspension, volume)
	end

	self._totalSuspensionChange = 0
end

function Audio._onHeartbeat(self: ControllersTypeClient.Audio, _deltaTime: number)
	local chassisVelocity = self.chassis.AssemblyLinearVelocity
	local localChassisVelocity = self.chassis.CFrame:VectorToObjectSpace(chassisVelocity)
	local forwardSpeed = math.abs(localChassisVelocity.Z)
	local actualEngineSpeed = self.engine:GetAttribute(CarConstants.ENGINE_SPEED_ATTRIBUTE)

	-- Adjust the engine playback speed/pitch and distortion based on the speed of the car.
	-- Use the max of either the car's target speed or its actual speed so that the engine still revs
	-- up in situations where it's not moving but the wheels are spinning.
	local engineSpeed = math.max(forwardSpeed, actualEngineSpeed)
	local enginePlaybackSpeed = ENGINE_PLAYBACK_SPEED + engineSpeed * ENGINE_PLAYBACK_SPEED_FACTOR
	self._engineLoop.PlaybackSpeed = enginePlaybackSpeed

	-- Adjust the tire driving volume based on the speed of the car
	local tiresVolume = TIRES_VOLUME * forwardSpeed * TIRES_VOLUME_FACTOR
	self._tiresLoop.Volume = tiresVolume

	-- Adjust the tire sliding volume based on the average wheel slippage
	local averageWheelSlip = getAverageWheelSlip(self.car)
	local tiresSlidingVolume = TIRES_SLIDING_VOLUME * averageWheelSlip * TIRES_SLIDING_VOLUME_FACTOR
	self._tiresSlidingLoop.Volume = tiresSlidingVolume

	-- Play suspension bumping sounds
	self:_updateSuspensionSounds()
end

function Audio.StartNitro(self: ControllersTypeClient.Audio)
	if self._nitroEnabled then
		return
	end

	self._nitroEnabled = true

	self._nitroStart:Play()
	self._nitroLoop:Play()
end

function Audio.StopNitro(self: ControllersTypeClient.Audio)
	if not self._nitroEnabled then
		return
	end

	self._nitroEnabled = false

	self._nitroStop:Play()
	self._nitroLoop:Stop()
end

function Audio.StartupEngine(self: ControllersTypeClient.Audio)
	if self._engineRunning then
		return
	end

	self._engineRunning = true

	self._engineStartup:Play()

	self._engineLoop.Volume = 0
	self._engineLoop:Play()

	-- Tween in the engine loop volume, since the startup sound is not instant
	local tweenInfo = TweenInfo.new(ENGINE_VOLUME_STARTUP_TWEEN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	local tween = TweenService:Create(self._engineLoop, tweenInfo, { Volume = ENGINE_VOLUME })
	tween:Play()
end

function Audio.ShutdownEngine(self: ControllersTypeClient.Audio)
	if not self._engineRunning then
		return
	end

	self._engineRunning = false

	self._engineShutdown:Play()
	self._engineLoop:Stop()
end

function Audio.PlayCollisionSound(self: ControllersTypeClient.Audio, volume: number)
	playRandomPlayer(self._collision, volume * COLLISION_VOLUME_FACTOR)
end

function Audio.Init(self: ControllersTypeClient.Audio)
	-- The tire driving and sliding loops should always be playing
	self._tiresLoop.Volume = 0
	self._tiresSlidingLoop.Volume = 0
	self._tiresLoop:Play()
	self._tiresSlidingLoop:Play()

	self._maid:GiveTask(RunService.Heartbeat:Connect(function(a0: number)
		self:_onHeartbeat(a0)
	end))
end

return Audio
