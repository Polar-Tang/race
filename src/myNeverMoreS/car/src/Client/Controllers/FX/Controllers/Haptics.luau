local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ControllerBaseClient = require(ReplicatedStorage.Nevermore.Custom.car.src.Client.ControllersUtils.ControllerBaseClient)
local ControllersTypeClient = require(ReplicatedStorage.Nevermore.Custom.car.src.Client.ControllersUtils.ControllersTypeClient)

local COLLISION_STRENGTH_FACTOR = 1 / 800 -- Amount to adjust haptic strength based on the average change

local Haptics = setmetatable({}, ControllerBaseClient)
Haptics.__index = Haptics
Haptics.ClassName = "Haptics"

function Haptics.new(config: ControllersTypeClient.ControllConstructor)
	local self = setmetatable(ControllerBaseClient.new(config), Haptics) :: ControllersTypeClient.ControllerBase

	self._hapticEffects = self.chassis.Haptic
	self._collisionHaptic = self._hapticEffects.CollisionHaptic
	self._nitroHaptic = self._hapticEffects.NitroHaptic
	self._enabled = false
	

	return self
end

function Haptics.PlayCollisionHaptic(self: ControllersTypeClient.Haptics, strength: number)
	if not self._enabled then
		return
	end
	local hapticStr = math.clamp(1 - strength * COLLISION_STRENGTH_FACTOR, 0.0, 1.0)
	self._collisionHaptic.Position = Vector3.new(hapticStr * self._collisionHaptic.Radius, 0, 0)
	self._collisionHaptic:Play()
end

function Haptics.StartNitro(self: ControllersTypeClient.Haptics)
	if not self._enabled then
		return
	end
	self._nitroHaptic:Play()
end

function Haptics.StopNitro(self: ControllersTypeClient.Haptics)
	if not self._enabled then
		return
	end
	self._nitroHaptic:Stop()
end

function Haptics.InitCustomHapticEffect(hapticEffect: HapticEffect)
	-- Initialize haptic effect with custom curve
	if hapticEffect.Type == Enum.HapticEffectType.Custom then
		local waveformCurve = hapticEffect:GetAttribute("WaveformCurve") -- a NumberSequence attribute to represent waveform
		local waveformCurveLengthMS = hapticEffect:GetAttribute("WaveformLengthMS") -- a number attribute to represent total length of the waveform in ms
		if waveformCurve and waveformCurveLengthMS then
			local floatCurve = {}
			for _, keypoint in waveformCurve.Keypoints do
				table.insert(
					floatCurve,
					FloatCurveKey.new(
						keypoint.Time * waveformCurveLengthMS,
						keypoint.Value,
						Enum.KeyInterpolationMode.Linear
					)
				)
			end
			hapticEffect.Type = Enum.HapticEffectType.Custom
			hapticEffect:SetWaveformKeys(floatCurve)
		end
	end
end

function Haptics.Init(self: ControllersTypeClient.Haptics)
	self.InitCustomHapticEffect(self._nitroHaptic)
	
end

function Haptics.Enable(self: ControllersTypeClient.Haptics)
	self._enabled = true
end

function Haptics.Disable(self: ControllersTypeClient.Haptics)
	self._enabled = false
end

return Haptics
