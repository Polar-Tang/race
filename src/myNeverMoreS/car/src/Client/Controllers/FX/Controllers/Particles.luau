local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ControllerBaseClient =
	require(ReplicatedStorage.Nevermore.Custom.car.src.Client.ControllersUtils.ControllerBaseClient)
local ControllersTypeClient =
	require(ReplicatedStorage.Nevermore.Custom.car.src.Client.ControllersUtils.ControllersTypeClient)

local Particles = setmetatable({}, ControllerBaseClient)
Particles.__index = Particles
Particles.ClassName = "Particles"

function Particles.new(config: ControllersTypeClient.ControllConstructor): ControllersTypeClient.Particles
	local self = setmetatable(ControllerBaseClient.new(config), Particles) :: ControllersTypeClient.ControllerBase

	self._rightNitroEmitterAttachment = self.chassis.RightNitroEmitterAttachment
	self._leftNitroEmitterAttachment = self.chassis.LeftNitroEmitterAttachment
	return self
end

function Particles.StartNitro(self: ControllersTypeClient.Particles)
	if self._nitroEnabled then
		return
	end

	self._nitroEnabled = true

	-- Enable the particle emitters and lights inside the nitro emitter attachments
	for _, emitter in self._rightNitroEmitterAttachment:GetChildren() do
		emitter.Enabled = true
	end
	for _, emitter in self._leftNitroEmitterAttachment:GetChildren() do
		emitter.Enabled = true
	end
end

function Particles.StopNitro(self: ControllersTypeClient.Particles)
	if not self._nitroEnabled then
		return
	end

	self._nitroEnabled = false

	-- Disable the particle emitters and lights inside the nitro emitter attachments
	for _, emitter in self._rightNitroEmitterAttachment:GetChildren() do
		emitter.Enabled = false
	end
	for _, emitter in self._leftNitroEmitterAttachment:GetChildren() do
		emitter.Enabled = false
	end
end

return Particles
