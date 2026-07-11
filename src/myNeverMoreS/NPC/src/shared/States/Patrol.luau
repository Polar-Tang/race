local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StateMachine = require(ReplicatedStorage.StateMachine)
local State = StateMachine.State

-- Patrol picks a random point within range of the NPC's home and walks there.
-- It self-limits via `patrol_duration` (set from the movement's estimated travel
-- time) so a stuck NPC still returns to Idle.
local Patrol = State.new("Patrol")

Patrol.Transitions = {
	require(script.Parent.Parent.Transitions.FinnishPatrol),
	require(script.Parent.Parent.Transitions.Die),
}

function Patrol:OnEnter(data)
	-- Not eating while we walk.
	if data.EatController then
		data.EatController:StopAnim()
	end

	data.patrolStartTime = data.timer

	local goal: Vector3? = data.TargetingController
		and data.TargetingController:getRandomNearbyPosition(data.range)
	if not goal then
		-- Nowhere to go; bail back to Idle promptly.
		data.patrol_duration = 0
		return
	end

	if data.MovementController then
		data.MovementController:LookTo(goal)
		-- MoveTo returns the estimated travel time; pad it so we don't cut the
		-- walk short if the NPC has to path around something.
		data.patrol_duration = data.MovementController:MoveTo(goal) + 3
	end
end

function Patrol:OnLeave(data)
	-- Reset the patrol interval clock from the moment patrol ended.
	data.lastPatrolTime = data.timer
	if data.MovementController then
		data.MovementController:Stop()
	end
end

function Patrol:OnHeartbeat(data, deltaTime)
	data.timer += deltaTime
end

return Patrol
