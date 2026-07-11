-- SoundController
--
-- Responsibility: NPC sound effects (footsteps, eating, idle chirps...). Sounds
-- are parented to the NPC's root so they're positional. Only instantiated for
-- the local owner (see setCtx) to avoid every client blasting the same SFX.
--
-- Sound sources, in priority order:
--   1. ctx.stats.sounds -> { name = "rbxassetid://..." }
--   2. Sound instances parented under pet/Sounds named by intent
-- Missing clips are silent no-ops.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Maid = require(ReplicatedStorage.Nevermore.Quenty.maid.Shared.Maid)

local SoundController = {}
SoundController.ClassName = "SoundController"
SoundController.__index = SoundController

function SoundController.new(ctx: any, _serviceBag: any?, _player: Player?)
	local self = setmetatable({}, SoundController)

	self.pet = ctx.pet
	self.root = ctx.root
	self._ids = (ctx.stats and ctx.stats.sounds) or {}
	self._folder = ctx.pet:FindFirstChild("Sounds")
	self._sounds = {} :: { [string]: Sound }
	self._maid = Maid.new()

	return self
end

function SoundController:_getSound(name: string): Sound?
	if self._sounds[name] then
		return self._sounds[name]
	end

	local sound: Sound?
	local id = self._ids[name]
	if id then
		sound = Instance.new("Sound")
		sound.Name = name
		sound.SoundId = id
		sound.Parent = self.root or self.pet
		self._maid:GiveTask(sound)
	elseif self._folder then
		local found = self._folder:FindFirstChild(name)
		if found and found:IsA("Sound") then
			sound = found
		end
	end

	if sound then
		self._sounds[name] = sound
	end
	return sound
end

function SoundController:Play(name: string)
	local sound = self:_getSound(name)
	if sound then
		sound:Play()
	end
end

function SoundController:Stop(name: string)
	local sound = self._sounds[name]
	if sound then
		sound:Stop()
	end
end

-- DI entry point. No sibling dependencies; present so setCtx can inject uniformly.
function SoundController:Init(_controllers) end

function SoundController:Destroy()
	for _, sound in self._sounds do
		sound:Stop()
	end
	self._maid:DoCleaning()
	table.clear(self._sounds)
end

return SoundController
