-- MovementController
--
-- Sole responsibility: move the NPC. States ask it to walk somewhere and it
-- drives the Humanoid there, returning an *estimated* travel time (seconds) so
-- the calling state can time itself out if the NPC gets stuck.
--
-- Maid discipline (important): this controller keeps a PRIVATE `_maid` for its
-- own move-scratch (Heartbeat/MoveToFinished connections). It must never touch
-- the binder maid -- that one owns this controller plus its siblings, so
-- cleaning it here would cascade into pet:Destroy() mid-move. The binder maid
-- calls OUR :Destroy(); we never call into it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Maid = require(ReplicatedStorage.Nevermore.Quenty.maid.Shared.Maid)

local LOOK_TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local MIN_DURATION = 0.25 -- never report an instant move

local MovementController = {}
MovementController.ClassName = "MovementController"
MovementController.__index = MovementController

function MovementController.new(ctx: any, _serviceBag: any?, _player: Player?)
	local self = setmetatable({}, MovementController)

	self.pet = ctx.pet
	self.root = ctx.root
	self.humanoid = ctx.humanoid
	self.speed = ctx.stats and ctx.stats.walkSpeed or 8
	self.isMoving = false
	self._maid = Maid.new()

	if self.humanoid then
		self.humanoid.PlatformStand = false
		self.humanoid.WalkSpeed = self.speed
	end

	return self
end

-- Walk to a world position. Returns the estimated travel time in seconds so the
-- caller (e.g. Patrol) can pad it into a state duration.
function MovementController:MoveTo(target: Vector3): number
	self._maid:DoCleaning()

	if not self.humanoid or not self.root then
		return MIN_DURATION
	end

	local distance = (target - self.root.Position).Magnitude
	local duration = math.max(distance / math.max(self.speed, 0.1), MIN_DURATION)

	self.isMoving = true

	-- MoveToFinished fires on arrival OR the 8s Roblox timeout; either way the
	-- move is over from our perspective.
	self._maid:GiveTask(self.humanoid.MoveToFinished:Once(function()
		self.isMoving = false
	end))

	self.humanoid:MoveTo(target)

	return duration
end

-- Rotate to face a point without teleporting (a short tween on the root CFrame).
function MovementController:LookTo(to: Vector3): Tween?
	if not self.root then
		return nil
	end
	local targetCFrame = CFrame.lookAt(self.root.Position, Vector3.new(to.X, self.root.Position.Y, to.Z))
	local tween = TweenService:Create(self.root, LOOK_TWEEN_INFO, { CFrame = targetCFrame })
	self._maid:GiveTask(tween)
	tween:Play()
	return tween
end

-- Halt the current move without destroying the NPC.
function MovementController:Stop()
	self._maid:DoCleaning()
	self.isMoving = false
	if self.humanoid and self.root then
		-- Cancel the pending MoveTo by targeting our own position.
		self.humanoid:MoveTo(self.root.Position)
	end
end

function MovementController:IsMoving(): boolean
	return self.isMoving
end

function MovementController:Destroy()
	self._maid:DoCleaning()
	self.isMoving = false
end

return MovementController
