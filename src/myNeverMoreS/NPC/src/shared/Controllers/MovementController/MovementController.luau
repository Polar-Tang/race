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
local RunService = game:GetService("RunService")

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

	-- Network ownership + anchoring can only be handled on the server, and only
	-- there does server-side Humanoid:MoveTo need to be authoritative.
	if RunService:IsServer() then
		self:_prepareForServerControl()
	end

	return self
end

-- Makes the rig actually drivable by the server:
--   1. unanchor every part (ServerStorage templates are usually anchored, and an
--      anchored assembly silently ignores Humanoid:MoveTo)
--   2. hand simulation to the server via SetNetworkOwner(nil) so the server's
--      MoveTo calls win (a nearby client can otherwise auto-claim ownership)
function MovementController:_prepareForServerControl()
	if not self.pet then
		return
	end

	for _, part in self.pet:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = false
		end
	end

	-- Set ownership on the assembly's actual root part.
	local rootPart = (self.humanoid and self.humanoid.RootPart) or self.root
	if not rootPart then
		return
	end

	local canSet, reason = rootPart:CanSetNetworkOwnership()
	if canSet then
		rootPart:SetNetworkOwner(nil) -- nil == the server
	else
		warn(`[MovementController] cannot take network ownership of {self.pet.Name}: {reason}`)
	end
end

-- DI entry point (called by setCtx once every sibling controller exists). Wiring
-- the animator here lets MoveTo drive the walk clip in lockstep with real motion:
-- it starts when we start driving and stops the instant we arrive.
function MovementController:Init(controllers)
	self._animator = controllers and controllers.AnimatorController
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

	-- We own the walk clip: play it exactly when motion starts...
	if self._animator then
		self._animator:PlayWalk()
	end

	-- ...and stop it the moment the humanoid arrives. MoveToFinished fires on
	-- arrival OR the 8s Roblox timeout; either way the move (and the walk) is
	-- over. Stopping here -- not in Patrol:OnLeave -- means the clip ends the
	-- instant the NPC physically stops, with no lingering slide.
	self._maid:GiveTask(self.humanoid.MoveToFinished:Once(function()
		self.isMoving = false
		if self._animator then
			self._animator:StopWalk()
		end
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
	-- Interruption safety: DoCleaning() dropped the MoveToFinished handler, so
	-- stop the walk clip here too (e.g. Idle/Patrol yanking us out mid-walk).
	if self._animator then
		self._animator:StopWalk()
	end
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
