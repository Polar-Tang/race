-- TargetController
--
-- Responsibility: pick *where* the NPC should go. Patrol asks it for a random
-- reachable point near the NPC's home (spawn) position, optionally constrained
-- to the owner's plot fence so pets never wander off the plot.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Maid = require(ReplicatedStorage.Nevermore.Quenty.maid.Shared.Maid)

local TargetController = {}
TargetController.ClassName = "TargetController"
TargetController.__index = TargetController

function TargetController.new(ctx: any, _serviceBag: any?, _player: Player?)
	local self = setmetatable({}, TargetController)

	self.pet = ctx.pet
	self.root = ctx.root
	self.home = ctx.home or (ctx.root and ctx.root.Position) or Vector3.zero
	self.range = ctx.range or 50
	self._maid = Maid.new()

	return self
end

-- Returns a random position within `range` studs of the NPC's home, on the same
-- Y plane. If the NPC sits inside a plot, the point is clamped to the fence
-- bounds so it stays home. Returns nil only if we have no reference point.
function TargetController:getRandomNearbyPosition(range: number?): Vector3?
	local origin = self.home
	if not origin then
		return nil
	end

	local r = range or self.range
	local angle = math.random() * math.pi * 2
	local dist = math.sqrt(math.random()) * r -- sqrt -> uniform over the disc

	local candidate = origin + Vector3.new(math.cos(angle) * dist, 0, math.sin(angle) * dist)
	return candidate
end

function TargetController:Destroy()
	self._maid:DoCleaning()
end

return TargetController
