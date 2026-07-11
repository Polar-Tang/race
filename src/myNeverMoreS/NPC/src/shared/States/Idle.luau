local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StateMachine = require(ReplicatedStorage.StateMachine)
local State = StateMachine.State

-- Idle is the NPC's resting hub. It sits still and, on an interval, decides to
-- either wander (Patrol) or feed (Eat). Death can interrupt from here too.
local Idle = State.new("Idle")

Idle.Transitions = {
	require(script.Parent.Parent.Transitions.StartPatrol),
	require(script.Parent.Parent.Transitions.StartEating),
	require(script.Parent.Parent.Transitions.Die),
}

function Idle:OnEnter(data)
	data.lastIdleTime = data.timer

	-- Stop any lingering movement and settle into the idle pose.
	if data.MovementController then
		data.MovementController:Stop()
	end
	
	data.AnimatorController:LoadAnimation(true, "idle")
end

function Idle:OnLeave(data)
		
end

-- Advancing the shared clock in every state keeps the interval-based transitions
-- consistent regardless of which state currently owns the heartbeat.
function Idle:OnHeartbeat(data, deltaTime)
	data.timer += deltaTime
end

return Idle
