-- PetAnimatorController
--
-- Responsibility: own the NPC's animation tracks. Other controllers/states ask
-- it to play or stop a named animation ("walk", "eat", "idle", "die", ...).
--
-- Animation sources, in priority order:
--   1. ctx.stats.animations -> { name = "rbxassetid://..." }
--   2. Animation instances parented under pet/Animations named by intent
-- Everything is guarded: a missing animator or missing clip is a silent no-op so
-- the brain keeps running even on a half-set-up model.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Maid = require(ReplicatedStorage.Nevermore.Quenty.maid.Shared.Maid)

local PetAnimatorController = {}
PetAnimatorController.ClassName = "PetAnimatorController"
PetAnimatorController.__index = PetAnimatorController

local function resolveAnimator(pet: Model, humanoid: Humanoid?): Animator?
	if humanoid then
		local animator = humanoid:FindFirstChildOfClass("Animator")
		if animator then
			return animator
		end
		-- Create one so LoadAnimation works even on server-built rigs.
		local newAnimator = Instance.new("Animator")
		newAnimator.Parent = humanoid
		return newAnimator
	end
	local controller = pet:FindFirstChildOfClass("AnimationController")
	return controller and controller:FindFirstChildOfClass("Animator") or nil
end

function PetAnimatorController.new(ctx: any, _serviceBag: any?, _player: Player?)
	local self = setmetatable({}, PetAnimatorController)

	self.pet = ctx.pet
	self.humanoid = ctx.humanoid
	self._animator = resolveAnimator(ctx.pet, ctx.humanoid)
	self._ids = (ctx.stats and ctx.stats.animations) or {}
	self._folder = ctx.pet:FindFirstChild("Animations")
	self._tracks = {} :: { [string]: AnimationTrack }
	self._maid = Maid.new()

	return self
end

-- Lazily build (and cache) an AnimationTrack for a named intent.
function PetAnimatorController:_getTrack(name: string): AnimationTrack?
	if not self._animator then
		return nil
	end
	if self._tracks[name] then
		return self._tracks[name]
	end

	local animation: Animation?
	local id = self._ids[name]
	if id then
		animation = Instance.new("Animation")
		animation.AnimationId = id
	elseif self._folder then
		local found = self._folder:FindFirstChild(name)
		if found and found:IsA("Animation") then
			animation = found
		end
	end

	if not animation then
		return nil
	end

	local ok, track = pcall(function()
		return self._animator:LoadAnimation(animation)
	end)
	if not ok or not track then
		return nil
	end

	self._tracks[name] = track
	self._maid:GiveTask(track)
	if id and animation then
		self._maid:GiveTask(animation)
	end
	return track
end

-- Play or stop a named animation. Mirrors the (play: boolean, name: string)
-- signature used elsewhere in the codebase.
function PetAnimatorController:LoadAnimation(play: boolean, name: string)
	local track = self:_getTrack(name)
	if not track then
		return
	end
	if play then
		if not track.IsPlaying then
			track:Play()
		end
	else
		track:Stop()
	end
end

function PetAnimatorController:Play(name: string)
	self:LoadAnimation(true, name)
end

function PetAnimatorController:Stop(name: string)
	self:LoadAnimation(false, name)
end

function PetAnimatorController:StopAll()
	for _, track in self._tracks do
		track:Stop()
	end
end

function PetAnimatorController:Destroy()
	self:StopAll()
	self._maid:DoCleaning()
	table.clear(self._tracks)
end

return PetAnimatorController
