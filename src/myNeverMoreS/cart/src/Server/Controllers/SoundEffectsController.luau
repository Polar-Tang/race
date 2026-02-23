--!strict
local AbstractController = require(script.Parent.AbstractController)
local ControllersTypes = require(script.Parent.ControllersTypes)

local SoundEffectsController = setmetatable({}, AbstractController)
SoundEffectsController.__index = SoundEffectsController

function SoundEffectsController.new(
	config: ControllersTypes.ControllConstructor
): ControllersTypes.SoundEffectsController
	local self = setmetatable(AbstractController.new(config), SoundEffectsController) :: any

	local Cart = config.cart

	local Base = Cart:WaitForChild("Base")

	self._screech = Base:WaitForChild("Screech")
	self._kachunk = {
		Base:WaitForChild("Kachunk1"),
		Base:WaitForChild("Kachunk2"),
	}
	self._breakSound = Base:WaitForChild("Break")

	self._screechFrac = 0
	self._screechTimeLeft = 0

	self._kachunkDistance = 0
	self._whichKachunk = 0
	return self
end

function SoundEffectsController.playSounds(
	self: ControllersTypes.SoundEffectsController,
	dt: number,
	velocity: number,
	screeching: boolean
)
	local speedFrac = math.min(1, velocity / 25)
	local soundVolume = ((speedFrac - 0.3) / 0.7) ^ 2

	if screeching and math.random(1, 10) == 1 then
		self._screechTimeLeft = 0.1
	else
		self._screechTimeLeft -= dt
	end
	if self._screechTimeLeft > 0 then
		self._screechFrac = math.min(1, self._screechFrac + dt * 5)
	else
		self._screechFrac = math.max(0, self._screechFrac - dt * 2)
	end
	self._screech.Playing = self._screechFrac > 0
	self._screech.Volume = 0.3 * soundVolume * self._screechFrac
	self._screech.PlaybackSpeed = 0.95 + speedFrac * 0.1

	if self._kachunkDistance > 20 then
		local kachunk = self._kachunk[self._whichKachunk % 2 + 1]
		self._whichKachunk += 1
		self._kachunkDistance = 0
		kachunk.Volume = 0.1 * speedFrac
		kachunk.PlaybackSpeed = 0.9 + speedFrac * 0.2
		kachunk:Play()
	end
end

function SoundEffectsController.stopSounds(self: ControllersTypes.SoundEffectsController)
	for i = 1, #self._kachunk do
		self._kachunk[i]:Stop()
	end
	self._screech:Stop()
end

function SoundEffectsController.movedBy(self: ControllersTypes.SoundEffectsController, distance: number)
	self._kachunkDistance += distance
end

function SoundEffectsController.playSound(self: ControllersTypes.SoundEffectsController, soundName: string)
	local map = { ["BreakSound"] = self._breakSound }

	local sound: Sound? = map[soundName]
	if not sound then
		print("Invalid ", soundName)
		return
	end
	sound:Play()
end

return SoundEffectsController
